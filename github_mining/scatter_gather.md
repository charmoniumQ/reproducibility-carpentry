## The problem

For this lesson, I thought I would test how many Conda lockfiles are resolvable today compared to the number of Spack lockfiles.
That workflow would contain 3 for-loops, where I want to map a function over each value of a list:

```
for package_manager in package_managers():
    for project in mine_github for projects():
        for commit in mine_project_for_commits():
            result = test(package_manager, project, commit)
            # aggregation code not shown
```

I know how many package managers I am testing ahead of time, but not the number of relevant projects on GitHub or commits for each project.
Also the absolute numbers are quite large; I could have thousands of projects each with hundreds of commits.
This necessitates using the "scatter/gather" paradigm of workflows.

This is when I realized Scatter/gather is a good "challenge problem" to assess the flexibility of workflow engines.
Abstraclty, the problem is given {`f: () -> Bag[T]`, `g: T -> U`, `h: Bag[U] -> U`, and `h` is associative}, compute `h([g(elem) for elem in f()])`.

There are several questions we can ask about a given workflow engine's solution to this challenge problem.

- **Semantically batched `g` or single-`g`**: Does the workflow model `g` as operating on single elements or partitions of elements?
  - If the workflow engine offers caching, the cache-key of `g` should be a single element, not a partition. If the cache-key is a partition, if any element within the partition changes, the entire cache entry is invalid. If any element is inserted or removed in this partition or a prior one, the entire cache entry is invalid.
  - This is also important for reusability; there might already be a wrapper that operates on single elements, so it can be more easily reused if the "map" part of scatter/map/gather operates on single-elements.
- **Schedule batched `g` or single-`g`**: Does the workflow schedule one jobs of `g` for every element or does it batch jobs of `g`?
  - If the output of `f` is large and `g` is relatively fast, then scheduling one job per element creates contention on the scheduler. While the programmer should "see" `g` operating on a single-element, under-the-hood, the workflow engine should probably schedule `g` in a fixed-number of almost-equal batches. This only matters if the product of the cardinality of the output `f`  times the scheduler overhead per task is a significant fraction of the execution time. I think many real-world workflows, like my GitHub mining workflow, would require batching.
- **Blocking/streaming-`g`** and **Blocking/streaming-`h`**: Can jobs of `g` be dispatched while the `f` is still in progress? Can jobs of `h` be dispatched while some jobs of `g` are still in progress?
  - `f` may be able to output its first result quickly, but take much longer to get to its last result. Ideally, the system can be working on the first few jobs of `g` while the last few results of `f` are coming in, to maximize parallelism. As in a tree-reduction, `h` is The workflow engine should assume that `h` is associative, so `h([u0, u1, u2, u3]) == h([h([u0, u1]), h([u2, u3])])`. `h([u0, u1])` need not wait for `u2` and `u3` to become available. The streaming-`g` feature only matters for workloads where computing all of `f` is slow, but computing the first result (or first batch of results) of `f` is fast. The streaming-`h` feature only matters when `h` is slow. I believe my many workflows, including my GitHub mining workflow, would benefit from streaming-`g` and streaming-`h`.
- **De/duplicated visualization**: Does a visualization of the workflow DAG contain multiple copies of `g`?
  - Ideally, the workflow engine would support two visualizations: one showing how the workflow is coded and another showing how it is executed. The coding-visualization should not show multiple copies of `g`, eliminating unnecessary "chart noise". Instead `f` could be shaped like an inverted funnel, and `h` like a funnel, indicating the scatter/gather. This would be more suitable for inclusion in a paper. The execution-visualization may include copies of `g` and `h`, which would be more suitable for performance debugging. One could set the number of partitions to 1 for the sake of plotting the coding-visualization from a workflow engine that only has an execution-visualization. However, one would still have to change the node shapes or bold the arrows.

## Results

- Snakemake has two possible implementations of scatter/gather: `g` will not be cached effectively (former solution) XOR `g` will be batched (latter solution). In either case, Snakemake has streaming-`g` but not streaming-`h`; there is no way to indicate that `h` is a reduction.
  - Literal [`scatter`/`gather` functions](https://snakemake.readthedocs.io/en/v8.11.6/snakefiles/rules.html#defining-scatter-gather-processes).
    - **Semantically batched `g`**: ❌. Snakemake has between-workflow caching, but the cache-key depends on the whole batch.
    - **Schedule batched `g`**: ✅
    - **Streaming-`g`**: ✅
    - **Blocking-`h`** ❌. Snakemake has no way of indicating that `h` is associative, so it has no way of streaming `h`.
    - **Duplicated visualization**: ❌
  - Specify the `input` dynamically (formerly `dyanamic`, now [`checkpoint`](https://snakemake.readthedocs.io/en/v8.11.6/snakefiles/rules.html#data-dependent-conditional-execution)):
    - **Semantically single `g`**: ✅
    - **Schedule single `g`**: ❌
    - **Streaming-`g`**: ✅
    - **Blocking-`h`** ❌. As before, there is no indicator in Snakemake that `h` is associative.
    - **Incomplete or deduplicated visualization**: ❌. Visualizing before execution does not show the dynamic edges; visualizing after shows the dynamic edges duplicated for each item.
- Parsl doesn't refer to scatter/gather by name, but it can implement them with [`join_app`s](https://parsl.readthedocs.io/en/stable/userguide/joins.html): `join_app_g_h(f())` where `join_app_g_h = parsl.join_app(lambda lst: h(*[g(elem) for elem in lst]))` (due to Ben Clifford).
  - **Semantically single `g`**: ❌. This is quite annoying, since Snakemake has between-workflow caching, but the cache-key depends on the whole batch.
  - **Schedule single `g`**: 🤔. However, Parsl's scheduler is highly performant with a many tasks, so this might be more ok.
  - **Streaming-`g`**: ❌. `f` returns a Python list, so the whole object has to be constructed before iterating/dispatching `g`.
  - **Blocking-`h`** ❌. I can't find any reference to a tree-reduction or similar algorithm in Parsl's documentation, even in their [MapReduce](https://parsl.readthedocs.io/en/stable/userguide/workflow.html#mapreduce) example.
- Dask: `f().map(g).reduction(list, h) `.
  - **Semantically single `g`**: ✅. Note that Dask has no first-party between-invocation caching, but a third-party solution could work (e.g., [charmonium.cache](https://charmoniumq.github.io/charmonium.cache/)), since `g` semantically operates on single items.
  - **Schedule batch `g`**: ✅.
  - **Streaming-`g`**: ✅.  Due to representing batches of `g` in the DAG, Dask has streaming-`g`.
  - **"Semi-streaming-`h`"** 🤔. [Reductions](https://docs.dask.org/en/stable/generated/dask.bag.Bag.reduction.html#dask.bag.Bag.reduction) is implemented in 2-levels: `h` on each partition, and `h` on the result of that. The former invocation of `h` is dispatchable as soon as the batch of `g` is done, but the second invocation has to wait for all; this is "in-between" fully streaming-`h` and fully blocked-`h`. If there are a small number of partitions, this is not a big problem, however, this opposes our desire to combat worker imbalance by using a large number of partitions.
- WDL has [scatter/gather](https://github.com/openwdl/wdl/blob/wdl-1.1/SPEC.md#scatter-statement).
  - **Semantically single `g`**: ✅
  - **Schedule batch/single `g`**: ❔. Depends on implementation
  - **Blocking-`g`**: ❌.  Scatter outputs `Array[X]` and gather inputs `Array[X]`, so I think it is unlikely that an implementation would be able to implement streaming-`g`.
  - **Blocking-`h`"** ❌. As with Snakemake, there is no way to indicate that `h` is associative, so no implementation can implement streaming-`h`, without deviating significantly from th standard.
- The same can be said about CWL as was said about WDL. See their [scatter/gather](http://www.commonwl.org/user_guide/topics/workflows.html#scattering-steps)
- Cromwell has the limitations inherent to WDL:
  - **Semantically single `g`**: ✅. Cromwell implements [call caching](https://cromwell.readthedocs.io/en/latest/cromwell_features/CallCaching/), which presumably would work well since `g` semantically operates on a single item.
  - **Schedule single `g`**: ❌. Cromwell schedules [1 job per element](https://cromwell.readthedocs.io/en/latest/developers/bitesize/workflowExecution/executionAndValueStoreExamples/#handling-scatters).
  - **Blocking-`g`**: ❌, due to WDL.
  - **Blocking-`h`"** ❌, due to WDL.
- Toil
  - **Semantically single `g`**: ✅. Toil does not appear to have caching. What they refer to as [caching](https://toil.readthedocs.io/en/latest/appendices/architecture.html#caching) in their documentation refers to within-invocation, same-computational-node. However, changing Toil or injecting caching from a preprocessor step would be possible since `g` semantically operates on a single items.
  - **Schedule single `g`**: ❌. Toil appears to create [1 job per element](https://toil.readthedocs.io/en/latest/appendices/architecture.html#toil-support-for-common-workflow-language).
  - **Blocking-`g`**: ❌, due to CWL.
  - **Blocking-`h`"** ❌, due to CWL.
- Spark/PySpark: `f().map(g).reduce(h)`.
  - **Semantically single `g`**: ✅. Spark has no first-party between-invocation caching, but a third-party solution could work (e.g., [charmonium.cache](https://charmoniumq.github.io/charmonium.cache/)), since `g` semantically operates on single-items.
  - **Schedule `g`**: ❔. I couldn't dig through the Spark internals to determine this.
  - **Streaming-`g`**: ✅, believe Spark can utilize streaming-`g` and streaming-`h` in its query planner, but I couldn't dig enough into the internals easily.
  - **Streaming-`h`"** ✅.
 
