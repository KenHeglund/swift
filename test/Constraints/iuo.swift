// RUN: %target-typecheck-verify-swift

func basic() {
  var i: Int! = 0
  let _: Int = i
  i = 7
}

func takesIUOs(i: Int!, j: inout Int!) -> Int {
  j = 7
  return i
}

struct S {
  let i: Int!
  var j: Int!
  let k: Int
  var m: Int
  var n: Int! {
    get {
      return m
    }
    set {
      m = newValue
    }
  }
  var o: Int! {
    willSet {
      m = newValue
    }
    didSet {
      m = oldValue
    }
  }

  func fn() -> Int! { return i }

  static func static_fn() -> Int! { return 0 }

  subscript(i: Int) -> Int! {
    set {
      m = newValue
    }
    get {
      return i
    }
  }

  init(i: Int!, j: Int!, k: Int, m: Int) {
    self.i = i
    self.j = j
    self.k = k
    self.m = m
  }

  init!() {
    i = 0
    j = 0
    k = 0
    m = 0
  }
}

func takesStruct(s: S) {
  let _: Int = s.i
  let _: Int = s.j
  var t: S! = s
  t.j = 7
}

var a: (Int, Int)! = (0, 0)
a.0 = 42

var s: S! = S(i: nil, j: 1, k: 2, m: 3)
_ = s.i
let _: Int = s.j
_ = s.k
s.m = 7
s.j = 3

let _: Int = s[0]

struct T {
  let i: Float!
  var j: Float!

  func fn() -> Float! { return i }
}

func overloaded() -> S { return S(i: 0, j: 1, k: 2, m: 3) }
func overloaded() -> T { return T(i: 0.5, j: 1.5) }

let _: Int = overloaded().i

func cflow(i: Int!, j: inout Bool!, s: S) {
  let k: Int? = i
  let m: Int = i
  let b: Bool! = i == 0

  if i == 7 {
    if s.i == 7 {
    }
  }

  let _ = b ? i : k
  let _ = b ? i : m
  let _ = b ? j : b

  let _ = b ? s.j : s.k

  if b {}
  if j {}
  let _ = j ? 7 : 0
}

func forcedResultInt() -> Int! {
  return 0
}

let _: Int = forcedResultInt()

func forcedResult() -> Int! {
  return 0
}

func forcedResult() -> Float! {
  return 0
}

func overloadedForcedResult() -> Int {
  return forcedResult()
}

func forceMemberResult(s: S) -> Int {
  return s.fn()
}

func forceStaticMemberResult() -> Int {
  return S.static_fn()
}

func overloadedForceMemberResult() -> Int {
  return overloaded().fn()
}

func overloadedForcedStructResult() -> S! { return S(i: 0, j: 1, k: 2, m: 3) }
func overloadedForcedStructResult() -> T! { return T(i: 0.5, j: 1.5) }

let _: S = overloadedForcedStructResult()
let _: Int = overloadedForcedStructResult().i

func id<T>(_ t: T) -> T { return t }

protocol P { }
extension P {
  func iuoResult(_ b: Bool) -> Self! { }
  static func iuoResultStatic(_ b: Bool) -> Self! { }
}

func cast<T : P>(_ t: T) {
  let _: (T) -> (Bool) -> T? = id(T.iuoResult as (T) -> (Bool) -> T?)
  let _: (Bool) -> T? = id(T.iuoResult(t) as (Bool) -> T?)
  let _: T! = id(T.iuoResult(t)(true))
  let _: (Bool) -> T? = id(t.iuoResult as (Bool) -> T?)
  let _: T! = id(t.iuoResult(true))
  let _: T = id(t.iuoResult(true))
  let _: (Bool) -> T? = id(T.iuoResultStatic as (Bool) -> T?)
  let _: T! = id(T.iuoResultStatic(true))
}

class rdar37241550 {
  public init(blah: Float) { fatalError() }
  public convenience init() { fatalError() }
  public convenience init!(with void: ()) { fatalError() }

  static func f(_ fn: () -> rdar37241550) {}
  static func test() {
    f(rdar37241550.init) // no error, the failable init is not applicable
  }
}

class B {}
class D : B {
  var i: Int!
}

func coerceToIUO(d: D?) -> B {
  return d as B! // expected-warning {{using '!' here is deprecated and will be removed in a future release}}
}

func forcedDowncastToOptional(b: B?) -> D? {
  return b as! D! // expected-warning {{using '!' here is deprecated and will be removed in a future release}}
}

func forcedDowncastToObject(b: B?) -> D {
  return b as! D! // expected-warning {{using '!' here is deprecated and will be removed in a future release}}
}

func forcedDowncastToObjectIUOMember(b: B?) -> Int {
  return (b as! D!).i // expected-warning {{using '!' here is deprecated and will be removed in a future release}}
}

func forcedUnwrapViaForcedCast(b: B?) -> B {
  return b as! B! // expected-warning {{forced cast from 'B?' to 'B' only unwraps optionals; did you mean to use '!'?}}
  // expected-warning@-1 {{using '!' here is deprecated and will be removed in a future release}}
}

func conditionalDowncastToOptional(b: B?) -> D? {
  return b as? D! // expected-warning {{using '!' here is deprecated and will be removed in a future release}}
}

func conditionalDowncastToObject(b: B?) -> D {
  return b as? D! // expected-error {{value of optional type 'D?' must be unwrapped to a value of type 'D'}}
  // expected-note@-1 {{coalesce using '??' to provide a default when the optional value contains 'nil'}}
  // expected-note@-2 {{force-unwrap using '!' to abort execution if the optional value contains 'nil'}}
  // expected-warning@-3 {{using '!' here is deprecated and will be removed in a future release}}
}

// Ensure that we select the overload that does *not* involve forcing an IUO.
func sr6988(x: Int?, y: Int?) -> Int { return x! }
func sr6988(x: Int, y: Int) -> Float { return Float(x) }

var x: Int! = nil
var y: Int = 2

let r = sr6988(x: x, y: y)
let _: Int = r

// SR-11998 / rdar://problem/58455441
class C<T> {}
var sub: C! = C<Int>()

// FIXME: We probably shouldn't support this, we don't support other
// 'direct call' features such as default arguments for curried calls.
struct CurriedIUO {
  func silly() -> Int! { nil }
  func testSilly() {
    let _: Int = CurriedIUO.silly(self)()
  }
}

// SR-15219 (rdar://83352038): Make sure we don't crash if an IUO param becomes
// a placeholder.
func rdar83352038() {
  func foo(_: UnsafeRawPointer) -> Undefined {} // expected-error {{cannot find type 'Undefined' in scope}}
  let _ = { (cnode: AlsoUndefined!) -> UnsafeMutableRawPointer in // expected-error {{cannot find type 'AlsoUndefined' in scope}}
    return foo(cnode)
  }
}
