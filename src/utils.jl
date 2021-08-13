"""
    memory_use(df)

Calculate the memory use which equivalent to `maximum(max.(df.len_before, df.len))` or
`maximum(df.len)`
"""
function memory_use(df)
    if hasproperty(df, :len_before)
        return maximum(max.(df.len, df.len_before))
    else
        return maximum(df.len)
    end
end

"""
    projected_energy(df)

Calculate projected energy from data frame `df`. Returns `NaN`s if `med_and_errs` fails.
"""
function projected_energy(df)
    try
        return med_and_errs(ratio_of_means(df.hproj, df.vproj))
    catch
        return (NaN, NaN, NaN, NaN, NaN)
    end
end

"""
    set_coherence_and_norm(target, ref, coherence, norm)

Randomly set coherence and norm of vector to specified value. Vector is assumed to have a
coherence of 1. Write it to target.
"""
function set_coherence_and_norm!(target, ref, coherence, target_norm)
    prob = coherence / 2 + 0.5
    alpha = target_norm / norm(ref, 1)
    for (k, v) in pairs(localpart(ref))
        sign = ifelse(rand() < prob, 1, -1)
        target[k] = v * alpha * sign
    end
    return target
end
