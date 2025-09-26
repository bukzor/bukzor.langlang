@0xf1e2d3c4b5a69708;

# System F-omega representation
# The target of our termination-preserving encoding

struct FomegaTerm {
  union {
    # Variables (De Bruijn indices for alpha-equivalence)
    variable :group {
      name @0 :Text;        # For debugging/pretty-printing
      index @1 :UInt32;     # De Bruijn index
    }

    # Lambda abstraction (System F)
    abstraction :group {
      parameter @2 :Text;
      paramType @3 :FomegaType;
      body @4 :FomegaTerm;
    }

    # Function application
    application :group {
      function @5 :FomegaTerm;
      argument @6 :FomegaTerm;
    }

    # Type abstraction (System F - polymorphism)
    typeAbstraction :group {
      typeParam @7 :Text;
      kind @8 :Kind;
      body @9 :FomegaTerm;
    }

    # Type application
    typeApplication :group {
      term @10 :FomegaTerm;
      type @11 :FomegaType;
    }

    # Let bindings (for optimization)
    let :group {
      name @12 :Text;
      value @13 :FomegaTerm;
      body @14 :FomegaTerm;
    }

    # Recursive definitions (carefully controlled)
    fix :group {
      name @15 :Text;
      type @16 :FomegaType;
      body @17 :FomegaTerm;
      terminationProof @18 :TerminationProof;
    }

    # Data constructors
    constructor :group {
      name @19 :Text;
      type @20 :FomegaType;
      args @21 :List(FomegaTerm);
    }

    # Pattern matching
    match :group {
      scrutinee @22 :FomegaTerm;
      cases @23 :List(MatchCase);
    }

    # Literals (base cases)
    literal :group {
      value @24 :Literal;
    }
  }
}

struct FomegaType {
  union {
    # Type variables
    typeVariable :group {
      name @0 :Text;
      index @1 :UInt32;     # De Bruijn index
    }

    # Function types
    arrow :group {
      domain @2 :FomegaType;
      codomain @3 :FomegaType;
    }

    # Universal quantification (System F)
    forall :group {
      variable @4 :Text;
      kind @5 :Kind;
      body @6 :FomegaType;
    }

    # Type constructors (System F-omega)
    typeConstructor :group {
      constructor @7 :FomegaType;
      arguments @8 :List(FomegaType);
    }

    # Base types
    baseType :group {
      name @9 :Text;        # "Bool", "Int", "String", etc.
    }

    # Recursive types
    mu :group {
      variable @10 :Text;
      body @11 :FomegaType;
    }

    # Effect types (for Free monad encoding)
    effect :group {
      effects @12 :List(EffectSignature);
      resultType @13 :FomegaType;
    }
  }
}

struct Kind {
  union {
    # Kind of types (*)
    star @0 :Void;

    # Kind of type constructors (* -> *)
    arrow :group {
      domain @1 :Kind;
      codomain @2 :Kind;
    }

    # Row kinds (for extensible records)
    row :group {
      fields @3 :List(Text);
    }
  }
}

struct MatchCase {
  pattern @0 :Pattern;
  body @1 :FomegaTerm;
}

struct Pattern {
  union {
    wildcard @0 :Void;
    variable @1 :Text;
    constructor :group {
      name @2 :Text;
      args @3 :List(Pattern);
    }
    literal @4 :Literal;
  }
}

struct Literal {
  union {
    unit @0 :Void;
    bool @1 :Bool;
    int @2 :Int64;
    float @3 :Float64;
    text @4 :Text;
  }
}

struct EffectSignature {
  name @0 :Text;
  paramTypes @1 :List(FomegaType);
  returnType @2 :FomegaType;
}

# The key insight: if we can prove termination, we can use recursion
struct TerminationProof {
  union {
    # Structural recursion (arguments get smaller)
    structural :group {
      measure @0 :Text;     # What decreases
      wellFounded @1 :Bool; # Is the relation well-founded?
    }

    # Bounded recursion (finite fuel)
    bounded :group {
      maxSteps @2 :UInt64;
    }

    # Totality (no recursion at all)
    total @3 :Void;

    # Corecursion (productive, generates infinite data)
    productive :group {
      outputGuarantee @4 :Text;
    }

    # Termination by typing (strong normalization)
    strongNormalization @5 :Void;
  }
}

# Metadata for optimization and debugging
struct FomegaMetadata {
  # Source mapping
  originalAST @0 :Text;  # Reference back to source

  # Optimization hints
  canInline @1 :Bool;
  isPure @2 :Bool;
  complexity @3 :ComplexityBound;

  # For GPU compilation
  parallelizable @4 :Bool;
  gpuFriendly @5 :Bool;

  # Self-interpretation markers
  interpreterLevel @6 :UInt32;  # Meta-level for self-interpretation
}

struct ComplexityBound {
  union {
    constant @0 :Void;
    logarithmic @1 :Void;
    linear @2 :Void;
    polynomial :group {
      degree @3 :UInt32;
    }
    exponential @4 :Void;
    unknown @5 :Void;
  }
}