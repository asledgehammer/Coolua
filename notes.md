# GENERAL:
- TODO: Implement Stack object.

# METHODS:
- TODO: Make addMethod() check for override with flags like static, final, and visibility reduction.

# RECORD:
- Records are finalized.
- Records do not have super-context / hierarchy.
- Records have finalized private fields.
- explicit constructors are optional but requires assigning field(s).
- implicit constructor is all declared fields in order of definition.
- Method-names should have `name()`, not `get<Name>()` or `is<Name>()`.
- Records can implement interfaces.
- Records can have inner structs.
- Records cannot be abstract because of finalization.