# TODO import HorizonSideRobots as HSR
# TODO unify move[_...]! function interface (return path)
# TODO move with predicate - stop_cond or while_cond
# TODO move with predicate - make_before_move | make_after_move

# XXX putmarker! after or before move?

using HorizonSideRobots


function reverse_side(side::HorizonSide)::HorizonSide
    return HorizonSide((Int(side)+2)%4)
end


function reverse_path(path::Vector{HorizonSide})::Vector{HorizonSide}
    reversed_sides::Vector{HorizonSide} = []
    foreach(side -> push!(reversed_sides, reverse_side(side)), path)

    return reverse!(reversed_sides)
end


# move to direction side untill stop_cond
function HorizonSideRobots.move!(stop_cond::Function, robot::Robot, side::HorizonSide)::Vector{HorizonSide}
    traveled_path::Vector{HorizonSide} = []

    while (!stop_cond(robot, side))
        HorizonSideRobots.move!(robot, side)
        push!(traveled_path, side)
    end

    return traveled_path
end


function HorizonSideRobots.move!(stop_cond::Function,
                                 robot::Robot, side::HorizonSide;
                                 pre_act::Function, post_act::Function)::Vector{HorizonSide}
    traveled_path::Vector{HorizonSide} = []

    while (!stop_cond(robot, side))
        pre_act(robot)
        HorizonSideRobots.move!(robot, side)
        push!(traveled_path, side)
        post_act(robot)
    end

    return traveled_path
end


function HorizonSideRobots.move!(robot::Robot, path::Vector{HorizonSide})::Tuple{Bool, Vector{HorizonSide}}
    traveled_path::Vector{HorizonSide} = []

    for side in path
        if (!isborder(robot, side))
            move!(robot, side)
            push!(traveled_path, side)
        else
            return (false, traveled_path) # traveled_path != path
        end
    end

    return (true, path) # traveled_path == path
end


function HorizonSideRobots.move!(robot::Robot, side::HorizonSide, steps::Integer)::Tuple{Bool, Integer}
    traveled_steps::Integer = 0

    while (traveled_steps != steps)
        if (!isborder(robot, side))
            HorizonSideRobots.move!(robot, side)
            traveled_steps += 1
        else
            return (false, traveled_steps)
        end
    end

    return (true, steps)
end


function mark_direction!(robot::Robot, side::HorizonSide)::Integer
    steps_in_direction::Integer = 0

    putmarker!(robot)
    while (!isborder(robot, side))
        move!(robot, side)
        steps_in_direction += 1
        putmarker!(robot)
    end

    return steps_in_direction
end
