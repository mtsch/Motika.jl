"""
@plant kwargs... begin
    # Rimu code
    lomc!(...)
end

Convenience macro for running multiple Rimu runs with different parameters.

# Keyword arguments

* Parameters of the form `i=range`. Each of these is converted into a for-loop and used in the
  file names.
* `path = "."`: directory to save results in.
* `id = ""`: id prepended to names of files.
* `distribute=false`: run the outermost for-loop with `@distributed`. Note: use `@everywere`
  for any setup outside the main body of `plant`.

# Example 1: probing a plateau with continuations

```julia
add = near_uniform(BoseFS{8,8})
dv = DVec(add => 1, style=IsDynamicSemistochastic())
params = RunTillLastStep(laststep=10_000)

@plant path="./plateau" id="plateau" nt=1000:1000:10_000 begin
    H = HubbardReal1D(add; 2)
    params.step = 0
    s_strat = DoubleLogUpdate(targetwalkers=nt)
    lomc!(H, dv; params, s_strat)
end
```

# Example 2: probing interaction strengths

```
@plant path="./params" id="params" u=0.1:0.1:1 v=0.1:0.1:1 begin
    add = BoseFS2C((0,0,0,0,3,0,0,0,0,0), (0,0,0,0,1,0,0,0,0,0))
    H = HubbardMom1D2C(add; u, v)
    s_strat = DoubleLogUpdate(targetwalkers=10_000)
    dv = DVec(add => 1, style=IsDynamicSemistochastic())
    lomc!(H, dv; s_strat)
end
```
"""
macro plant(exprs...)
    # Collect ranges and keyword arguments.
    prefix = ""
    path = "."
    distribute = false
    names = []
    ranges = []
    for ex in exprs[1:end-1]
        if @capture(ex, (id = str_))
            prefix = str
        elseif @capture(ex, (path = str_))
            path = str
        elseif @capture(ex, (distribute = dist_))
            distribute = dist
        elseif @capture(ex, (name_ = range_))
            push!(names, name)
            push!(ranges, range)
        else
            error("ranges must be assignment expressions. Got `$ex`")
        end
    end

    info_expr = Expr(:tuple)
    info_expr.args = names

    namestrings = map(names) do n
        str = "_$n"
        :(string($str, $n))
    end
    id = Expr(:call)
    id.args = [:string, prefix, namestrings...]

    name_expr = map(names) do n
        str = "$n = "
        :(string($str, $n, ", "))
    end
    pop!(name_expr[end].args) # remove trailing comma.
    readable_id = Expr(:call)
    readable_id.args = [:string, name_expr...]


    body = quote
        if is_mpi_root()
            printstyled(stderr, "[ ", $prefix, ": ", color=:green, bold=true)
            println(stderr, $readable_id)
        end
        $(exprs[end])
    end

    loop_body = postwalk(body) do ex
        if ex isa Expr && ex.head == :call && ex.args[1] == :lomc!
            # On lomc!, save data frame, add parameters as columns and write it to file.
            ex = :((df, _) = $ex; df.id = fill($id, size(df, 1)))
            for name in names
                ex = :($ex; df.$name = fill($name, size(df, 1)))
            end
            quote
                $ex
                if is_mpi_root()
                    RimuIO.save_df(joinpath($path, string($id, ".arrow")), df)
                end
            end
        else
            ex
        end
    end

    # Create for loops for each parameter. If distribute is set, the outermost loop is
    # prefixed with @sync @distribute
    reverse!(names)
    reverse!(ranges)
    expr = loop_body
    for (name, range) in zip(names[1:end-1], ranges[1:end-1])
        expr = quote
            for $name in $range
                $expr
            end
        end
    end
    name, range = names[end], ranges[end]
    if distribute
        expr = quote
            @distributed for $name in $range
                $expr
            end
        end
    else
        expr = quote
            for $name in $range
                $expr
            end
        end
    end
    plantping = distribute ? "Distributed planting" : "Planting"
    message = "[ $plantping $prefix to "
    return esc(
        quote
        path = $path
        if is_mpi_root()
            printstyled(stderr, $message; color=:green, bold=true)
            println(stderr, "`", path, "`")
        end
        mkpath($path)
        $expr
    end)
end
