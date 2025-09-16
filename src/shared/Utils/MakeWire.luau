--!strict
return function(source: Instance, target: Instance): Wire
    local wire = Instance.new("Wire")
    wire.SourceInstance = source
    wire.TargetInstance = target
    wire.Parent = source

    return wire
end
