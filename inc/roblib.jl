# TODO import HorizonSideRobots as HSR
# TODO move with predicate - stop_cond or while_cond
# TODO move with predicate - make_before_move | make_after_move


using HorizonSideRobots


function reverse_side(side::HorizonSide)::HorizonSide
    return HorizonSide((Int(side)+2)%4)
end


function reverse_path(path::Vector{HorizonSide})::Vector{HorizonSide}
    reversed_sides::Vector{HorizonSide} = []
    foreach(side -> push!(reversed_sides, reverse_side(side)), path)

    return reverse!(reversed_sides)
end


function reverse_path(path::Vector{Tuple{HorizonSide, T}})::Vector{Tuple{HorizonSide, T}} where T <: Integer
    return reverse!(map(p -> (reverse_side(p[1]), p[2]), path))
end


# move to direction side untill stop_cond
function HorizonSideRobots.move!(stop_cond::Function, robot::Robot, side::HorizonSide)::Integer
    steps_untill_stop_cond::Integer = 0

    while (!stop_cond(robot, side))
        HorizonSideRobots.move!(robot, side)
        steps_untill_stop_cond += 1
    end

    return steps_untill_stop_cond
end


function move_with_act!(stop_cond::Function,
                        robot::Robot, side::HorizonSide;
                        pre_act::Function, post_act::Function)::Vector{HorizonSide}
    traversed_path::Vector{HorizonSide} = []

    while (!stop_cond(robot, side))
        pre_act(robot)
        HorizonSideRobots.move!(robot, side)
        push!(traversed_path, side)
        post_act(robot)
    end

    return traversed_path
end


function HorizonSideRobots.move!(robot::Robot, path::Vector{HorizonSide})::Tuple{Bool, Vector{HorizonSide}}
    traversed_path::Vector{HorizonSide} = []

    for side in path
        (isborder(robot, side)) && (return (false, traversed_path)) # traversed_path != path
        move!(robot, side)
        push!(traversed_path, side)
    end

    return (true, path) # traversed_path == path
end


function HorizonSideRobots.move!(robot::Robot, path::Vector{Tuple{HorizonSide, T}})::Tuple{Bool, Vector{Tuple{HorizonSide, T}}} where T <: Integer
    traversed_path::Vector{Tuple{HorizonSide, T}} = []

    for (side, steps) in path
        success, steps_traversed = move!(robot, side, steps)
        push!(traversed_path, (side, steps_traversed))

        (!success) && (return (false, traversed_path))
    end

    return (true, traversed_path)
end


function HorizonSideRobots.move!(robot::Robot, side::HorizonSide, steps::T)::Tuple{Bool, Integer} where T <: Integer
    traversed_steps::T = 0

    while (traversed_steps < steps)
        (isborder(robot, side)) && (return (false, traversed_steps))
        move!(robot, side)
        traversed_steps += 1
    end

    return (true, steps)
end


function iscorner(robot::Robot)::Bool
    for side_v in [Nord, Sud]
        for side_h in [West, Sud]
            (isborder(robot, side_v) && isborder(robot, side_h)) && (return true)
        end
    end

    return false
end


function move_into_corner!(robot::Robot; side_v::HorizonSide=Nord, side_h::HorizonSide=West)::Tuple{Bool, Vector{Tuple{HorizonSide, Integer}}}
    traversed_path::Vector{Tuple{HorizonSide, Integer}} = []

    # TODO infinite loop in a trap
    #
    # |  R  |  <-- trap
    # + --- +
    while (!isborder(robot, side_v) || !isborder(robot, side_h))
        for side in [side_v, side_h]
            steps = move!(isborder, robot, side)
            push!(traversed_path, (side, steps))
        end
    end

    # NOTE do not change return type now to save function interface
    return (true, traversed_path)
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


function mark_direction!(robot::Robot, side::HorizonSide, steps::T)::Tuple{Bool, T} where T <: Integer
    traversed_steps::T = 0

    putmarker!(robot)
    while (traversed_steps < steps)
        (isborder(robot, side)) && (return (false, traversed_steps))

        move!(robot, side)
        traversed_steps += 1
        putmarker!(robot)
    end

    return (true, steps)
end


# mark when parity == 1
# function mark_chess_direction!(robot::Robot, side::HorizonSide, ::Val{0})::Int8
# function mark_chess_direction!(robot::Robot, side::HorizonSide, ::Val{1})::Int8
function mark_chess_direction!(robot::Robot, side::HorizonSide, init_parity::Int8)::Int8
    parity::Int8 = init_parity

    (parity == 1) && (putmarker!(robot))
    while (!isborder(robot, side))
        move!(robot, side)
        parity = (parity+1) % 2
        (parity == 1) && (putmarker!(robot))
    end

    return parity
end
