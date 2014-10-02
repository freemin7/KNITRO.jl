export
  newcontext, freecontext,
  load_param_file, save_param_file, load_tuner_file,
  init_problem, solve_problem, restart_problem,
  mip_init_problem, mip_solve_problem,
  set_param, get_param,
  get_number_FC_evals, get_number_GA_evals,
  get_number_H_evals, get_number_HV_evals,
  get_number_iters, get_number_cg_iters,
  get_abs_feas_error, get_rel_feas_error,
  get_abs_opt_error, get_rel_opt_error,
  get_mip_num_nodes, get_mip_num_solves,
  get_mip_abs_gap, get_mip_rel_gap,
  get_mip_incumbent_obj, get_mip_relaxation_bnd,
  get_mip_lastnode_obj, get_mip_incumbent_x

@doc """
Returns a pointer to the solver object that is used in all other KNITRO API calls.

A new KNITRO license is acquired and held until KTR_free has been called,
or until the calling program ends.
""" ->
function newcontext()
  ptr = @ktr_ccall(new,Ptr{Void},())
  if ptr == C_NULL
    error("KNITRO: Error creating solver")
  end
  ptr
end

@doc """
Returns a pointer to the solver object that is used in all other KNITRO API calls.

A new KNITRO license is acquired and held until KTR_free has been called,
or until the calling program ends.

This function also takes an argument [f] that sets a 'put string' callback
function to handle output generated by the KNITRO solver, and a pointer
[userParams] for passing user-defined data.
""" ->
function newcontext_puts(f::Function, userParams=C_NULL)
  cb = cfunction(f, Cint, (Ptr{Cchar}, Ptr{Void}))
  ptr = @ktr_ccall(new,Ptr{Void},(Ptr{Void}, Ptr{Void}),
                   cb, userParams)
  if ptr == C_NULL
    error("KNITRO: Error creating solver with put-string")
  end
  ptr
end  

@doc "Free all memory and release any KNITRO license acquired with [kp_env]" ->
function freecontext(kp_env::Ptr{Void})
  if kp_env != C_NULL
    return_code = @ktr_ccall(free, Int32, (Ptr{Void},), kp_env)
    if return_code != 0
      error("KNITRO: Error freeing memory")
    end
  end
end

# /** Allocate memory for a license from the Ziena License Manager for high
#  *  volume KNITRO applications.  The license will be checked out the first
#  *  time KTR_new_zlm is called.  The license must be checked in later by
#  *  calling ZLM_release_license.
#  *  Returns NULL on error.
#  */
# ZLM_context_ptr  KNITRO_API ZLM_checkout_license (void);

# function checkoutlicense()
#   ptr = @zlm_ccall(checkout_license,Ptr{Void},())
#   if ptr == C_NULL
#     error("KNITRO: Error checking out license")
#   end
#   ZLMcontext(ptr)
# end

# /** Returns a pointer to the solver object that is used in all other KNITRO
#  *  API calls.  Pass the license acquired by calling ZLM_checkout_license.
#  *  This function also takes an argument that sets a "put string" callback
#  *  function to handle output generated by the KNITRO solver, and a pointer
#  *  for passing user-defined data.  See KTR_set_puts_callback for more
#  *  information.
#  *  Returns NULL on error.
#  */
# KTR_context_ptr  KNITRO_API KTR_new_zlm (KTR_puts    * const  fnPtr,
#                                          void        * const  userParams,
#                                          ZLM_context * const  pZLMcontext);

# /** Release the KNITRO license and free allocated memory.
#  *  KNITRO will set the address of the pointer to NULL after freeing
#  *  memory, to help avoid mistakes.
#  *  Returns 0 if OK, nonzero if error.
#  */
# int  KNITRO_API ZLM_release_license (ZLM_context *  pZLMcontext);

# function releaselicense(zc::ZLMcontext)
#   if zc.context != C_NULL
#     return_code = @ktr_ccall(free, Int32, (Ptr{Void},), zc.context)
#     if return_code != 0
#       error("KNITRO: Error releasing license and freeing memory")
#     end
#     zc.context = C_NULL
#   end
# end

@doc "Reset all parameters to default values" ->
function reset_params_to_defaults(kp::KnitroProblem)
  return_code = @ktr_ccall(reset_params_to_defaults, Int32, (Ptr{Void},), kp.env)
  if return_code != 0
    error("KNITRO: Error resetting parameters to default values")
  end
end

@doc "Set all parameters specified in the given file" ->
function load_param_file(kp::KnitroProblem, filename::String)
  return_code = @ktr_ccall(load_param_file, Int32,
                           (Ptr{Void},Ptr{Cchar}),
                           kp.env, filename)
  if return_code != 0
    error("KNITRO: Error loading parameters from $(filename)")
  end
end

@doc "Write all current parameter values to a file" ->
function save_param_file(kp::KnitroProblem, filename::String)
  return_code = @ktr_ccall(save_param_file, Int32, (Ptr{Void},Ptr{Cchar}),
                           kp.env, filename)
  if return_code != 0
    error("KNITRO: Error writing parameters to $(filename)")
  end
end

@doc* "Set a parameter using either its (i) name::String, or (ii) id::Int" ->
function set_param(kp::KnitroProblem, name::String, value::Int32)
  return_code = @ktr_ccall(set_int_param_by_name, Int32, (Ptr{Void},Ptr{Cchar},Cint),
                           kp.env, name, value)
  if return_code != 0
    error("KNITRO: Error setting int parameter by name")
  end
end

function set_param(kp::KnitroProblem, name::String, value::String)
  return_code = @ktr_ccall(set_char_param_by_name, Int32, (Ptr{Void},Ptr{Cchar},Ptr{Cchar}),
                           kp.env, name, value)
  if return_code != 0
    error("KNITRO: Error setting char parameter by name")
  end
end

function set_param(kp::KnitroProblem, name::String, value::Float64)
  return_code = @ktr_ccall(set_double_param_by_name, Int32, (Ptr{Void},Ptr{Cchar},Cdouble),
                           kp.env, name, value)
  if return_code != 0
    error("KNITRO: Error setting float parameter by name")
  end
end

function set_param(kp::KnitroProblem, id::Int32, value::Int32)
  return_code = @ktr_ccall(set_int_param, Int32, (Ptr{Void},Cint,Cint),
                           kp.env, id, value)
  if return_code != 0
    error("KNITRO: Error setting int parameter by id")
  end
end

function set_param(kp::KnitroProblem, id::Int32, value::String)
  return_code = @ktr_ccall(set_char_param, Int32, (Ptr{Void},Cint,Ptr{Cchar}),
                           kp.env, id, value)
  if return_code != 0
    error("KNITRO: Error setting char parameter by id")
  end
end

function set_param(kp::KnitroProblem, id::Int32, value::Float64)
  return_code = @ktr_ccall(set_double_param, Int32, (Ptr{Void},Cint,Cdouble),
                           kp.env, id, value)
  if return_code != 0
    error("KNITRO: Error setting float parameter by id")
  end
end

@doc* "Get a parameter using either its (i) name::String, or (ii) id::Int" ->
function get_param(kp::KnitroProblem, name::String, value::Vector{Int32})
  @ktr_ccall(get_int_param_by_name, Int32, (Ptr{Void}, Ptr{Cchar}, Ptr{Cint}),
             kp.env, name, value)
end

function get_param(kp::KnitroProblem, name::String, value::Vector{Float64})
  @ktr_ccall(get_double_param_by_name, Int32, (Ptr{Void}, Ptr{Cchar}, Ptr{Cdouble}),
             kp.env, name, value)
end

function get_param(kp::KnitroProblem, id::Int32, value::Vector{Int32})
  @ktr_ccall(get_int_param, Int32, (Ptr{Void}, Cint, Ptr{Cint}),
             kp.env, id, value)
end

function get_param(kp::KnitroProblem, id::Int32, value::Vector{Float64})
  @ktr_ccall(get_double_param, Int32, (Ptr{Void}, Cint, Ptr{Cdouble}),
             kp.env, id, value)
end

@doc """
Similar to KTR_load_param_file but specifically allows user to
specify a file of options (and option values) to explore for
the KNITRO-Tuner.
""" ->
function load_tuner_file(kp::KnitroProblem, filename::String)
  return_code = @ktr_ccall(load_tuner_file, Int32, (Ptr{Void}, Ptr{Cchar}),
                           kp.env, filename)
  if return_code != 0
    error("KNITRO: Error loading tuner file $(filename)")
  end
end

@doc """
Copy the KNITRO release name into [release].  This variable must be
preallocated to have [length] elements, including the string termination
character.  For compatibility with future releases, please allocate at
least 15 characters.
""" ->
function get_release(length::Int32, release::String)
  @ktr_ccall(get_release, Any, (Cint, Ptr{Cchar}), kp.env, release)
end

@doc """
Set an array of absolute feasibility tolerances (one for each 
constraint and variable) to use for the termination tests.
""" ->
function set_feastols(kp::KnitroProblem, c_tol::Vector{Float64}, x_tol::Vector{Float64},
                     cc_tol::Vector{Float64})
  return_code = @ktr_ccall(set_feastols, Int32, (Ptr{Void}, Ptr{Cdouble}, Ptr{Cdouble},
                           Ptr{Cdouble}), kp.env, c_tol, x_tol, cc_tol)
  if return_code != 0
    error("KNITRO: Error setting feasibility tolerances")
  end
end

@doc """
Set names for model components passed in by the user/modeling
language so that KNITRO can internally print out these names.

KNITRO makes a local copy of all inputs, so the application may
free memory after the call.

This routine must be called after calling KTR_init_problem /
KTR_mip_init_problem and before calling KTR_solve / KTR_mip_solve.
""" ->
function set_names(kp::KnitroProblem, objName::String, varNames::Vector{String},
                   conNames::Vector{String})
  return_code = @ktr_ccall(set_names, Int32, (Ptr{Void}, Ptr{Cchar},
                           Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}),
                           kp.env, objName, varNames, conNames)
  if return_code != 0
    error("KNITRO: Error setting names for model components")
  end
end

# ----- Problem modification -----

@doc """
This function adds complementarity constraints to the problem.

It must be called after KTR_init_problem and before KTR_solve.
The two lists are of equal length, and contain matching pairs of
variable indices.  Each pair defines a complementarity constraint
between the two variables.  The function can be called more than once
to accumulate a long list of complementarity constraints in KNITRO's
internal problem definition.
""" ->
function add_contraints(kp::KnitroProblem,
                        ncons::Int32,
                        index1::Vector{Int32},
                        index2::Vector{Int32})
  return_code = @ktr_ccall(add_compcons, Int32, (Ptr{Void},Cint,Ptr{Cint},
                           Ptr{Cint}), kp.env,ncons,index1,index2)
  if return_code != 0
    error("KNITRO: Error adding complementary constraints")
  end
end

@doc """
Prepare KNITRO to re-optimize the current problem after
modifying the variable bounds from a previous solve.

It must be called after KTR_init_problem and precedes a call to KTR_solve.
""" ->
function chgvarbnds(kp::KnitroProblem,
                    x_L::Vector{Float64},
                    x_U::Vector{Float64})
  return_code = @ktr_ccall(add_compcons, Int32, (Ptr{Void},Ptr{Cdouble},
                           Ptr{Cdouble}), kp.env, x_L, x_U)
  if return_code != 0
    error("KNITRO: Error modifying variable bounds")
  end
end

# /* ----- Solving ----- */

@doc """
Initialize KNITRO with a new problem.  KNITRO makes a local copy of
all inputs, so the application may free memory after the call completes.
""" ->
function init_problem(kp::KnitroProblem,
                      objGoal::Int32,
                      objType::Int32,
                      x_L::Vector{Float64},
                      x_U::Vector{Float64},
                      c_Type::Vector{Int32},
                      c_L::Vector{Float64},
                      c_U::Vector{Float64},
                      jac_var::Vector{Int32},
                      jac_cons::Vector{Int32},
                      hess_rows::Vector{Int32},
                      hess_cols::Vector{Int32};
                      initial_x = C_NULL,
                      initial_lambda = C_NULL)
  n = length(x_L)
  m = length(c_Type)
  nnzJ = length(jac_var)
  nnzH = length(hess_rows)
  return_code = @ktr_ccall(init_problem, Int32, (Ptr{Void},Int32,Int32,Int32,
                           Ptr{Cdouble},Ptr{Cdouble},Int32,Ptr{Int32},
                           Ptr{Cdouble},Ptr{Cdouble},Int32,Ptr{Int32},
                           Ptr{Int32},Int32,Ptr{Int32},Ptr{Int32}, Ptr{Void},
                           Ptr{Void}), kp.env, n, objGoal, objType,
                           x_L, x_U, m, c_Type, c_L, c_U, nnzJ, jac_var,
                           jac_cons, nnzH, hess_rows, hess_cols,
                           initial_x, initial_lambda)
  if return_code != 0
    error("KNITRO: Error initializing problem")
  end
end
        
@doc* """
Call KNITRO to solve the problem.

If the application provides callback functions for evaluating the function,
constraints, and derivatives, then a single call to KTR_solve returns
the solution.  Otherwise, KNITRO operates in reverse communications mode and 
returns a status code that may request another call.

Returns one of the status codes KTR_RC_*. In particular:
0 - KNITRO is finished: x, lambda, and obj contain the optimal solution
1 - call KTR_solve again (reverse comm) with obj and c containing
    the objective and constraints evaluated at x
2 - call KTR_solve again (reverse comm) with objGrad and jac containing
    the objective and constraint first derivatives evaluated at x
3 - call KTR_solve again (reverse comm) with hess containing
    H(x,lambda), the Hessian of the Lagrangian evaluated at x and lambda
7 - call KTR_solve again (reverse comm) with hessVector containing
    the result of H(x,lambda) * hessVector
""" ->
function solve_problem(kp::KnitroProblem, x::Vector{Float64}, lambda::Vector{Float64},
                       evalStatus::Int32, obj::Vector{Float64}, cons::Vector{Float64},
                       objGrad::Vector{Float64}, jac::Vector{Float64}, hess::Vector{Float64},
                       hessVector::Vector{Float64})
  return_code = @ktr_ccall(solve, Int32, (Ptr{Void},Ptr{Cdouble},Ptr{Cdouble},
                           Int32,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},
                           Ptr{Cdouble},Ptr{Cdouble}, Any), kp.env, x, lambda, evalStatus,
                           obj, cons, objGrad, jac, hess, hessVector, kp)
  if return_code < 0
    error("KNITRO: Error solving problem")
  end
  return_code
end

function solve_problem(kp::KnitroProblem, x::Vector{Float64}, lambda::Vector{Float64},
                       evalStatus::Int32, obj::Vector{Float64})
  # For callback mode
  return_code = @ktr_ccall(solve, Int32, (Ptr{Void},Ptr{Cdouble},Ptr{Cdouble},
                           Int32,Ptr{Cdouble},Ptr{Void},Ptr{Void},Ptr{Void},
                           Ptr{Void},Ptr{Void}, Any), kp.env, x, lambda, evalStatus,
                           obj, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, kp)
  if return_code < 0
    error("KNITRO: Error solving problem (in callback mode")
  end
  return_code
end

@doc """
Prepare KNITRO to restart the current problem at a new start point [x_0, lambda_0].

If output to a file is enabled, this will erase the current file.
KNITRO parameter values are not changed by this call.
""" ->
function restart_problem(kp::KnitroProblem, x_0::Vector{Cdouble}, lambda_0::Vector{Cdouble})
  return_code = @ktr_ccall(restart, Int32, (Ptr{Void},Ptr{Cdouble},Ptr{Cdouble}),
                           kp.env, x_0, lambda_0)
  if return_code != 0
    error("KNITRO: Error restarting problem")
  end
end

@doc """
Initialize KNITRO with a new MIP problem.  KNITRO makes a local copy of
all inputs, so the application may free memory after the call completes.
""" ->
function mip_init_problem(kp::KnitroProblem,
                          objGoal::Int32,
                          objType::Int32,
                          objFnType::Int32,
                          x_Type::Vector{Int32},
                          x_L::Vector{Float64},
                          x_U::Vector{Float64},
                          c_Type::Vector{Int32},
                          c_FnType::Vector{Int32},
                          c_L::Vector{Float64},
                          c_U::Vector{Float64},
                          jac_var::Vector{Int32},
                          jac_cons::Vector{Int32},
                          hess_rows::Vector{Int32},
                          hess_cols::Vector{Int32};
                          initial_x = C_NULL,
                          initial_lambda = C_NULL)
  n = length(x_L)
  m = length(c_Type)
  nnzJ = length(jac_var)
  nnzH = length(hess_rows)
  return_code = @ktr_ccall(mip_init_problem, Int32, (Ptr{Void},Cint,Cint,Cint,
                           Cint,Ptr{Cint},Ptr{Cdouble},Ptr{Cdouble},Cint,Ptr{Cint},
                           Ptr{Cint},Ptr{Cdouble},Ptr{Cdouble},Cint,Ptr{Cint},
                           Ptr{Cint},Cint,Ptr{Cint},Ptr{Cint}, Ptr{Void},
                           Ptr{Void}), kp.env, n, objGoal, objType, objFnType,
                           x_Type, x_L, x_U, m, c_Type, c_FnType, c_L, c_U,
                           nnzJ, jac_var, jac_cons, nnzH, hess_rows, hess_cols,
                           initial_x, initial_lambda)
  if return_code != 0
    error("KNITRO: Error initializing MIP problem")
  end
end

@doc """
Set the branching priorities for integer variables.

Priorities must be positive numbers (variables with non-positive values
are ignored).  Variables with higher priority values will be considered
for branching before variables with lower priority values.  When
priorities for a subset of variables are equal, the branching rule is
applied as a tiebreaker.
""" ->
function set_branching_priorities(kp::KnitroProblem,
                                  xPriorities::Vector{Int})
  return_code = @ktr_ccall(mip_set_branching_priorities, Int32, (Ptr{Void},
                           Ptr{Cint}), kp.env, xPriorities)
  if return_code != 0
    error("KNITRO: Error setting MIP branching priorities")
  end
end  

@doc* """
Call KNITRO to solve the MIP problem.

If the application provides callback functions for evaluating the function,
constraints, and derivatives, then a single call to KTR_mip_solve returns the solution.
Otherwise, KNITRO operates in reverse communications mode and returns a status code
that may request another call.

Returns one of the status codes KTR_RC_*. In particular:
0 - KNITRO is finished: x, lambda, and obj contain the optimal solution
1 - call KTR_solve again (reverse comm) with obj and c containing
    the objective and constraints evaluated at x
2 - call KTR_solve again (reverse comm) with objGrad and jac containing
    the objective and constraint first derivatives evaluated at x
3 - call KTR_solve again (reverse comm) with hess containing
    H(x,lambda), the Hessian of the Lagrangian evaluated at x and lambda
7 - call KTR_solve again (reverse comm) with hessVector containing
    the result of H(x,lambda) * hessVector

If `gradopt` is set to compute finite differences for first derivatives,
then KTR_mip_solve will modify objGrad and jac; otherwise, these arguments
are not modified.
""" ->
function mip_solve_problem(kp::KnitroProblem, x::Vector{Float64}, lambda::Vector{Float64},
                           evalStatus::Int32, obj::Vector{Float64}, cons::Vector{Float64},
                           objGrad::Vector{Float64}, jac::Vector{Float64}, hess::Vector{Float64},
                           hessVector::Vector{Float64})
  return_code = @ktr_ccall(mip_solve, Int32, (Ptr{Void},Ptr{Cdouble},Ptr{Cdouble},
                           Int32,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},
                           Ptr{Cdouble},Ptr{Cdouble}, Any), kp.env, x, lambda, evalStatus,
                           obj, cons, objGrad, jac, hess, hessVector, kp)
  if return_code < 0
    error("KNITRO: Error solving MIP problem")
  end
  return_code
end

function mip_solve_problem(kp::KnitroProblem, x::Vector{Float64}, lambda::Vector{Float64},
                           evalStatus::Int32, obj::Vector{Float64})
  # For callback mode
  return_code = @ktr_ccall(mip_solve, Int32, (Ptr{Void},Ptr{Cdouble},Ptr{Cdouble},
                           Int32,Ptr{Cdouble},Ptr{Void},Ptr{Void},Ptr{Void},
                           Ptr{Void},Ptr{Void}, Any), kp.env, x, lambda, evalStatus,
                           obj, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, kp)
  if return_code != 0
    error("KNITRO: Error solving MIP problem (in callback mode")
  end
  return_code
end

@doc """
Set an array of relative stepsizes to use for the finite-difference
gradient/Jacobian computations when using finite-difference
first derivatives.

Finite-difference step sizes `delta` in KNITRO are
computed as:

          delta[i] = relStepSizes[i]*max(abs(x[i]),1)

The default relative step sizes for each component of `x` are `sqrt(eps)`
for forward finite differences, and `eps^(1/3)` for central finite
differences.  Use this function to overwrite the default values.
Array relStepSizes has length n and all values should be non-zero.
""" ->
function set_findiff_relstepsizes(kp::KnitroProblem,
                                  relStepSizes::Vector{Float64})
  return_code = @ktr_ccall(set_findiff_relstepsizes, Int32, (Ptr{Void},
                           Ptr{Cdouble}), kp.env, relStepSizes)
  if return_code != 0
    error("KNITRO: Error setting relative stepsizes for the finite-difference gradient/Jacobian computations")
  end
end

# ----- Reading solution properties -----

@doc """
Return the number of function evaluations requested by KTR_solve.

A single request evaluates the objective and all constraint functions.
""" ->
function get_number_FC_evals(kp::KnitroProblem)
  n = @ktr_ccall(get_number_FC_evals, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of function evaluations")
  end
  n
end

@doc """
Return the number of gradient evaluations requested by KTR_solve.

A single request evaluates first derivatives of the objective and
all constraint functions.
""" ->
function get_number_GA_evals(kp::KnitroProblem)
  n = @ktr_ccall(get_number_GA_evals, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of gradient evaluations")
  end
  n
end

@doc """
Return the number of Hessian evaluations requested by KTR_solve.

A single request evaluates second derivatives of the objective and
all constraint functions.
""" ->
function get_number_H_evals(kp::KnitroProblem)
  n = @ktr_ccall(get_number_H_evals, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of hessian evaluations")
  end
  n
end

@doc """
Return the number of Hessian-vector products requested by KTR_solve.

A single request evaluates the product of the Hessian of the
Lagrangian with a vector submitted by KNITRO.
""" ->
function get_number_HV_evals(kp::KnitroProblem)
  n = @ktr_ccall(get_number_HV_evals, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of hessian-vector evaluations")
  end
  n
end

# /* ----- Solution properties for continuous problems only ----- */

@doc "Return the number of iterations made by KTR_solve." ->
function get_number_iters(kp::KnitroProblem)
  n = @ktr_ccall(get_number_iters, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of iterations")
  end
  n
end

@doc "Return the number of conjugate gradient (CG) iterations made by KTR_solve" ->
function get_number_cg_iters(kp::KnitroProblem)
  n = @ktr_ccall(get_number_cg_iters, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error returning number of conjugate gradient iterations")
  end
  n
end

@doc """
Return the absolute feasibility error at the solution

Refer to the KNITRO manual section on Termination Tests for a
detailed definition of this quantity.
""" ->
function get_abs_feas_error(kp::KnitroProblem)
  n = @ktr_ccall(get_abs_feas_error, Float64, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting absolute feasibility error at solution")
  end
  n
end

# /** 
#  *  
#  *  Returns a negative number if there is a problem with kc.
#  */
# double  KNITRO_API KTR_get_rel_feas_error (const KTR_context_ptr  kc);
@doc """
Return the relative feasibility error at the solution

Refer to the KNITRO manual section on Termination Tests for a
detailed definition of this quantity.
""" ->
function get_rel_feas_error(kp::KnitroProblem)
  n = @ktr_ccall(get_rel_feas_error, Float64, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting relative feasibility error at solution")
  end
  n
end

@doc """
Return the absolute optimality error at the solution.

Refer to the KNITRO manual section on Termination Tests for a
detailed definition of this quantity.
""" ->
function get_abs_opt_error(kp::KnitroProblem)
  n = @ktr_ccall(get_abs_opt_error, Float64, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting absolute optimality error at solution")
  end
  n
end

@doc """
Return the relative optimality error at the solution.

Refer to the KNITRO manual section on Termination Tests for a
detailed definition of this quantity.
""" ->
function get_rel_opt_error(kp::KnitroProblem)
  n = @ktr_ccall(get_rel_opt_error, Float64, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting relative optimality error at solution")
  end
  n
end

@doc """
Return the solution status, objective, primal and dual variables.

The `status`, `obj`, `x`, and `lambda` vectors will be modified in-place
with the values returned by the routine.
""" ->
function get_solution(kp::KnitroProblem,
                      status::Vector{Int32},
                      obj::Vector{Float64},
                      x::Vector{Float64},
                      lambda::Vector{Float64})
  return_code = @ktr_ccall(get_solution, Int32, (Ptr{Void}, Ptr{Cint},
                           Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}), kp.env,
                           status, obj, x, lambda)
  if return_code < 0
    error("KNITRO: Error getting the solution status, objective, primal and dual variables")
  end
end

@doc "Return the values of the constraint vector c(x) in `c` through `cons`" ->
function get_constraint_values(kp::KnitroProblem, cons::Vector{Float64})
  return_code = @ktr_ccall(get_constraint_values, Int32, (Ptr{Void},
                           Ptr{Cdouble}), kp.env, cons)
  if return_code < 0
    error("KNITRO: Error getting the values of the constraint vector c(x)")
  end
end

@doc "Return the values of the objective gradient vector through `objGrad`" ->
function get_objgrad_values(kp::KnitroProblem, objGrad::Vector{Float64})
  return_code = @ktr_ccall(get_objgrad_values, Int32, (Ptr{Void},
                           Ptr{Cdouble}), kp.env, objGrad)
  if return_code < 0
    error("KNITRO: Error getting the values of the objective gradient vector")
  end
end

@doc "Return the values of the (non-zero sparse) constraint Jacobian through `jac`" ->
function get_jacobian_values(kp::KnitroProblem, jac::Vector{Float64})
  return_code = @ktr_ccall(get_jacobian_values, Int32, (Ptr{Void},
                           Ptr{Cdouble}), kp.env, jac)
  if return_code < 0
    error("KNITRO: Error getting the values of the constraint Jacobian")
  end
end

@doc """
Return the values of the (non-zero sparse) Hessian (or possibly Hessian
approximation) through `hess`.  This routine is currently only valid
if 1 of the 2 following cases holds:
  1) KTR_HESSOPT_EXACT (presolver on or off), or;
  2) KTR_HESSOPT_BFGS or KTR_HESSOPT_SR1, but only with the
     KNITRO presolver off (i.e. KTR_PRESOLVE_NONE).
""" ->
function get_hessian_values(kp::KnitroProblem,
                            hess::Vector{Float64})
  return_code = @ktr_ccall(get_hessian_values, Int32, (Ptr{Void},
                           Ptr{Cdouble}), kp.env, hess)
  if return_code < 0
    error("KNITRO: Error getting the values of the Hessian")
  end
end

    
# /* ----- Solution properties for MIP problems only ----- */

@doc "Return the number of nodes processed in MIP solve" ->
function get_mip_num_nodes(kp::KnitroProblem)
  n = @ktr_ccall(get_mip_num_nodes, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting the number of nodes processed in MIP solve")
  end
end

@doc "Return the number of continuous subproblems processed in MIP solve." ->
function get_mip_num_solves(kp::KnitroProblem)
  n = @ktr_ccall(get_mip_num_solves, Int32, (Ptr{Void},), kp.env)
  if n < 0
    error("KNITRO: Error getting the number of continuous subproblems processed in MIP solve")
  end
end

@doc """
Return the final absolute integrality gap in the MIP solve.

Refer to the KNITRO manual section on Termination Tests for
a detailed definition of this quantity.
""" ->
function get_mip_abs_gap(kp::KnitroProblem)
  return_code = @ktr_ccall(get_mip_abs_gap, Float64, (Ptr{Void},), kp.env)
  if return_code == KTR_RC_BAD_KCPTR
    error("KNITRO: Error getting the final absolute integrality gap in MIP solve.")
  end
  return_code
end

@doc """
Return the final relative integrality gap in the MIP solve.

Refer to the KNITRO manual section on Termination Tests for
a detailed definition of this quantity.
""" ->
function get_mip_rel_gap(kp::KnitroProblem)
  return_code = @ktr_ccall(get_mip_rel_gap, Float64, (Ptr{Void},), kp.env)
  if return_code == KTR_RC_BAD_KCPTR
    error("KNITRO: Error getting the final relative integrality gap in MIP solve.")
  end
  return_code
end

@doc "Return the objective value of the MIP incumbent solution" ->
function get_mip_incumbent_obj(kp::KnitroProblem)
  return_code = @ktr_ccall(get_mip_incumbent_obj, Float64, (Ptr{Void},), kp.env)
  if return_code == KTR_RC_BAD_KCPTR
    error("KNITRO: Error getting the objective value of the MIP incumbent solution.")
  end
  return_code
end

@doc "Return the value of the current MIP relaxation bound" ->
function get_mip_relaxation_bnd(kp::KnitroProblem)
  return_code = @ktr_ccall(get_mip_relaxation_bnd, Float64, (Ptr{Void},), kp.env)
  if return_code == KTR_RC_BAD_KCPTR
    error("KNITRO: Error getting the value of the current MIP relaxation bound.")
  end
  return_code
end

@doc "Return the objective value of the most recently solved MIP node subproblem" ->
function get_mip_lastnode_obj(kp::KnitroProblem)
  return_code = @ktr_ccall(get_mip_lastnode_obj, Float64, (Ptr{Void},), kp.env)
  if return_code == KTR_RC_BAD_KCPTR
    error("KNITRO: Error getting the objective value of the most recently solved MIP node subproblem.")
  end
  return_code
end

@doc """
Return the MIP incumbent solution in 'x' if it exists, and leaves 'x' unmodified.

Returns 1 if incumbent solution exists and call is successful;
        0 if no incumbent (i.e., integer feasible) exists
""" ->
function get_mip_incumbent_x(kp::KnitroProblem, x::Vector{Float64})
  return_code = @ktr_ccall(get_mip_incumbent_x, Int32, (Ptr{Void}, Ptr{Cdouble}), kp.env, x)
  if return_code < 0
    error("KNITRO: Error getting the MIP incumbent solution 'x'.")
  end
  return_code
end

@doc """
Compare the application's analytic first derivatives to a finite
difference approximation at x.  The objective and all constraint
functions are checked.

Returns one of the status codes KTR_RC_*. In particular:
0 - routine is finished
1 - call routine again (reverse comm) with obj and c containing
    the objective and constraints evaluated at x
2 - call routine again (reverse comm) with objGrad and jac containing
    the objective and constraint first derivatives evaluated at x
""" ->
function check_first_ders(kp::KnitroProblem,
                          x::Vector{Float64},
                          finiteDiffMethod::Int32,
                          absThreshold::Float64,
                          relThreshold::Float64,
                          evalStatus::Int32,
                          obj::Float64,
                          cons::Vector{Float64},
                          objGrad::Vector{Float64},
                          jac::Vector{Float64})
  return_code = @ktr_ccall(check_first_ders, Int32, (Ptr{Void}, Ptr{Cdouble}, Cint,
                           Cdouble, Cdouble, Cint, Cdouble, Ptr{Cdouble},
                           Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Void}), kp.env, x,
                           finiteDiffMethod, absThreshold, relThreshold, evalStatus,
                           obj, cons, objGrad, jac, C_NULL)
  if return_code < 0
    error("KNITRO: Error comparing the application's analytic first derivatives to a finite difference approximation at x")
  end
end