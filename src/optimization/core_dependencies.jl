"""
    outer_sigularity_constraint(steering_now::Steering, steering_next::Steering)

calculats the angle change of two sequential steps of the left front wheel.
The result of the subtraction should always be negativ.

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!
!marked with a  at the beginning !
#Arguments
- `steering_now::Steering`: the current state of the steering kinematics
- `steering_next::Steering`: The state of the steering kinematics when the rotating part of the steering is rotated about θz+1.

#Returns:
- Difference between the current outer turning angle of the wheel and the next step
"""
function outer_sigularity_constraint(steering_now::Steering, steering_next::Steering)
    return steering_now.δo - steering_next.δo
end


function outer_sigularity_constraint°(θx,θz,x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> outer_sigularity_constraint°")
    θ_tuple_now = θx,θz
    
    θ_tuple_next = θx,θz+1
    #println(":> $θ_tuple_next")
    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    steering_next = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)
    kinematicsUNTILmount°!(θ_tuple_next, steering_next, suspension)
    #println(":> ($x_rotational_radius, $z_rotational_radius, $track_lever_length, $tie_rod_length)")
    update°!(steering_now)
    update°!(steering_next)

    return outer_sigularity_constraint(steering_now, steering_next)
end




"""
    inner_sigularity_constraint(steering_now::Steering, steering_next::Steering)

calculats the angle change of two sequential steps of the right front wheel.
The result of the subtraction should always be negativ.

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!
!marked with a  at the beginning !
#Arguments
- `steering_now::Steering`: the current state of the steering kinematics
- `steering_next::Steering`: The state of the steering kinematics when the rotating part of the steering is rotated about θz+1.

#Returns:
- Difference between the current inner turning angle of the wheel and the next step
"""
function inner_sigularity_constraint(steering_now::Steering, steering_next::Steering)
    return steering_now.δi - steering_next.δi
end

function inner_sigularity_constraint°(θx,θz,x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> inner_sigularity_constraint°")
    θ_tuple_now = θx,θz

    θ_tuple_next = θx,θz+1

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    steering_next = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)
    kinematicsUNTILmount°!(θ_tuple_next, steering_next, suspension)
    
    update°!(steering_now)
    update°!(steering_next)

    return inner_sigularity_constraint(steering_now, steering_next)
end


"""
    angle_dependence(steering_now::Steering)

calculates the Diffrence of the front wheels steering angles.
!The inner steering angle should always be bigger then the outer!

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!
!marked with a  at the beginning !
#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Difference between the current turning angles of the front wheels
"""
function angle_dependence(steering_now::Steering)
    return steering_now.δi - steering_now.δo
end

function angle_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> angle_dependence°")
    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)

    update°!(steering_now)


    return angle_dependence(steering_now)
end



"""
    left_circsphere_plane_dependence(steering_now::Steering)

claculats the diffrence between the distance of the centers and the actual radius of the actual range of motion
of the tie rod. (Left side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!
!marked with a  at the beginning !
#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Dependence for the interaction between circle and sphere of the kinematic

"""
function left_circsphere_plane_dependence(steering_now::Steering)

    circ = Circle(steering_now.track_lever_mounting_points_ucs[1],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[1][:,3])
    sphere = Sphere(steering_now.sphere_joints[1],steering_now.tie_rod.length)

    normal = circ.normal/norm(circ.normal)        #circ.normal must be a unit vector
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ.center))

    return abs(d) - sphere.radius
end

function left_circsphere_plane_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> left_circsphere_plane_dependence°")
    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return left_circsphere_plane_dependence(steering_now)
end

"""
    right_circsphere_plane_dependence(steering_now::Steering)

claculats the diffrence between the distance of the circ/shere centers and the actual radius of the actual range of motion
of the tie rod. (Right side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!
!marked with a  at the beginning !
#Arguments
- `steering_now::Steering`: the current state of the steering kinematics


#Returns
- Dependence for the interaction between circle and sphere of the kinematic

"""
function right_circsphere_plane_dependence(steering_now::Steering) 

    circ = Circle(steering_now.track_lever_mounting_points_ucs[2],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[2][:,3])
    sphere = Sphere(steering_now.sphere_joints[2],steering_now.tie_rod.length)

    normal = circ.normal/norm(circ.normal)        #circ.normal must be a unit vector
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ.center))
    return abs(d) - sphere.radius
end

function right_circsphere_plane_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> right_circsphere_plane_dependence°")
    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return right_circsphere_plane_dependence(steering_now)
end

"""
    left_circcirc_min_intersec_dependence(steering_now::Steering)

calculates the Diffrence of the distance of the circ centeres d and the total length of both radii.
If the value of d is bigger then the total length of both radii there is no intersection of both circles.
(Left side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!

#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Dependence for the minimal interaction between circle and circle of the kinematic
"""

function left_circcirc_min_intersec_dependence(steering_now::Steering)
    #  from the GeoSpatialRelations package of the intersection() function

    circ1 = Circle(steering_now.track_lever_mounting_points_ucs[1],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[1][:,3])
    sphere = Sphere(steering_now.sphere_joints[1],steering_now.tie_rod.length)

    normal = circ1.normal/norm(circ1.normal)
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ1.center))

    r_circ_2 = sqrt(sphere.radius^2-d^2)
    center_circ_2 = sphere.center -d*normal

    circ2 = Circle(center_circ_2, r_circ_2, normal)

    if circ1.normal != circ2.normal
        throw(ArgumentError("The two circles do not lie in the same plane of three-dimensional space!"))
    end
    
    n_circ = circ1.normal
    n_circ = n_circ/norm(n_circ)        

    d = norm(circ1.center - circ2.center)                 

    return abs(d) - (abs(circ1.radius) + abs(circ2.radius))
end 

function left_circcirc_min_intersec_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> left_circcirc_min_intersec_dependence°")

    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return left_circcirc_min_intersec_dependence(steering_now)
end


"""
    left_circcirc_min_intersec_dependence(steering_now::Steering)

calculates the Diffrence of the distance of the circ centeres d and the total length of both radii.
If the value of d is bigger then the total length of both radii there is no intersection of both circles.
(Right side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!

#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Dependence for the minimal interaction between circle and circle of the kinematic
"""

function right_circcirc_min_intersec_dependence(steering_now::Steering)

    circ1 = Circle(steering_now.track_lever_mounting_points_ucs[2],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[2][:,3])
    sphere = Sphere(steering_now.sphere_joints[2],steering_now.tie_rod.length)

    normal = circ1.normal/norm(circ1.normal)
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ1.center))

    r_circ_2 = sqrt(sphere.radius^2-d^2)
    center_circ_2 = sphere.center -d*normal

    circ2 = Circle(center_circ_2, r_circ_2, normal)

    if circ1.normal != circ2.normal
        throw(ArgumentError("The two circles do not lie in the same plane of three-dimensional space!"))
    end
    
    n_circ = circ1.normal
    n_circ = n_circ/norm(n_circ)        

    d = norm(circ1.center - circ2.center)                 

    return abs(d) - (abs(circ1.radius) + abs(circ2.radius))
end 

function right_circcirc_min_intersec_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> right_circcirc_min_intersec_dependence°")

    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return right_circcirc_min_intersec_dependence(steering_now)
end

"""
    left_circcirc_max_intersec_dependence(steering_now::Steering)

calculates the Diffrence of the radius og the circle2 (tie rod) and the total length of the distance of the circ centeres d and the radius of the circle1 (track lever).
If the value of the radius of circle2 is bigger then ther is no intersect posible. circle1 lies in circle2.
(Left side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!

#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Dependence for the maximal interaction between circle and circle of the kinematic
"""
function left_circcirc_max_intersec_dependence(steering_now::Steering)
#  from the GeoSpatialRelations package of the intersection() function

    circ1 = Circle(steering_now.track_lever_mounting_points_ucs[1],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[1][:,3])
    sphere = Sphere(steering_now.sphere_joints[1],steering_now.tie_rod.length)

    normal = circ1.normal/norm(circ1.normal)
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ1.center))

    r_circ_2 = sqrt(sphere.radius^2-d^2)
    center_circ_2 = sphere.center -d*normal

    circ2 = Circle(center_circ_2, r_circ_2, normal)

    if circ1.normal != circ2.normal
        throw(ArgumentError("The two circles do not lie in the same plane of three-dimensional space!"))
    end

    n_circ = circ1.normal
    n_circ = n_circ/norm(n_circ)        

    d = norm(circ1.center - circ2.center)                 

    return abs(circ2.radius)-(abs(d) + abs(circ1.radius))
end 

function left_circcirc_max_intersec_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> left_circcirc_max_intersec_dependence°")

    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return left_circcirc_max_intersec_dependence(steering_now)
end


"""
    left_circcirc_max_intersec_dependence(steering_now::Steering)

calculates the Diffrence of the radius og the circle2 (tie rod) and the total length of the distance of the circ centeres d and the radius of the circle1 (track lever).
If the value of the radius of circle2 is bigger then ther is no intersect posible. circle1 lies in circle2.
(Right side of the kinematik steering mechanism)

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!

#Arguments
- `steering_now::Steering`: the current state of the steering kinematics

#Returns
- Dependence for the maximal interaction between circle and circle of the kinematic
"""
function right_circcirc_max_intersec_dependence(steering_now::Steering)
#  from the GeoSpatialRelations package of the intersection() function

    circ1 = Circle(steering_now.track_lever_mounting_points_ucs[2],steering_now.track_lever.length,steering_now.base_vec_wheel_ucs[2][:,3])
    sphere = Sphere(steering_now.sphere_joints[2],steering_now.tie_rod.length)

    normal = circ1.normal/norm(circ1.normal)
    d = (normal[1]*sphere.center[1] + normal[2]*sphere.center[2] + normal[3]*sphere.center[3] - sum(normal.*circ1.center))

    r_circ_2 = sqrt(sphere.radius^2-d^2)
    center_circ_2 = sphere.center -d*normal

    circ2 = Circle(center_circ_2, r_circ_2, normal)

    if circ1.normal != circ2.normal
        throw(ArgumentError("The two circles do not lie in the same plane of three-dimensional space!"))
    end

    n_circ = circ1.normal
    n_circ = n_circ/norm(n_circ)        

    d = norm(circ1.center - circ2.center)                 

    return abs(circ2.radius)-(abs(d) + abs(circ1.radius))
end 

function right_circcirc_max_intersec_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> right_circcirc_max_intersec_dependence°")

    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)


    return right_circcirc_max_intersec_dependence(steering_now)
end


"""
    track_circle_dependence(steering::Steering, measurments::Measurements)

calculates the diffrence of the max. ideal outer wheel angle and the current max. outer wheel angle.

!Instead of calling the kinematics in all conditions, the approach taken here is to use the properties of instantiation!

#Arguments
- `steering::Steering`: the last state of the steering kinematics
-`measurments::Measurements`: Instance of a specific all relevant Measurements of the vehicle

#Returns
- Dependence for the minmal track circle
"""
function track_circle_dependence(steering::Steering, measurments::Measurements)
    δo = steering.δo
    sind(δo)
    r_is = measurments.wheel_base / sind(δo) 
    return measurments.turning_radius - r_is
end


function track_circle_dependence°(θx, θz, x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)
    #println(":> track_circle_dependence°")

    θ_tuple_now = θx,θz

    steering_now = Steering(x_rotational_radius, z_rotational_radius, track_lever_length, tie_rod_length)


    suspension = Suspension(30)
    suspensionkinematics!(suspension)

    kinematicsUNTILmount°!(θ_tuple_now, steering_now, suspension)

    update°!(steering_now)

    measurments = Measurements(Chassi(),steering_now)

    return track_circle_dependence(steering_now, measurments)
end