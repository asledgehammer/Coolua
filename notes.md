# To Remember:
- Implement generics type-casting.
- FIXME: Store file path and line range for functions to not limit class definitions to one file path for visibility scopes.

#################################
NEXT: Make constructors signature-based with caching.
THEN: Make interface methods signature-based.
AFTER: Make enums work.
#################################

# GENERAL:
- TODO: Implement Package object.
- TODO: Implement Stack object.
- TODO: Implement Generics.
- TODO: Migrate `string.join()` to `table.concat`.
- TODO: (Ongoing) Cleanup Code.

# ENUM:
- TODO: Implement.

# INTERFACE:
- TODO: Implement.
- TODO: Implement default methods.
- TODO: Implement static methods.

# CLASS:
- TODO: Implement visibility-scope.
- TODO: Implement abstract constructor invocation check. (Must come from sub-class)
- TODO: Implement addSubInterface()
- TODO: Implement addSubEnum()
- TODO: Implement generics.

# FIELDS:
- TODO: Check assignment for type-compatability.

# METHODS:
- TODO: Make addMethod() check for override with flags like static, final, and visibility reduction.
- Make sure the returned value is valid for the return type(s).
- TODO: Make sure param definitions do not have anything other than a vararg if present.
- TODO: Make sure last param definition is vararg.

- TODO: Check method signatures _exactly_ for overrides.

# CONSTRUCTORS:
- Enforce super calls check for classes extending classes with non-empty constructors.
  - If a super-method exists without parameters, invoke it if anything is called. Use middle-methods to monitor in-constructor calls.