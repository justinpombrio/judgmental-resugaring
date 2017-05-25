open Util;;
open Term;;
open Grammar;;
open TestRunner;;
open Grammar;;
open Desugar;;
open Parse;;
open Judgment;;
open Infer;;
open Fresh;;

(* TODO:
   - Before resugaring, validate desugaring rules against the grammar.
 *)

let gram =
  parse_grammar_s "example_grammar"
    "Lit = VALUE;
     Decl = VARIABLE;
     Expr = VARIABLE | (Num Lit) | (Let Binds Expr) | (Lambda Params Expr)
          | (DsLet Binds Expr Params Args);
     Args = (End) | (Arg Expr Args);
     Params = (End) | (Param Decl Params);
     Binds = (End) | (Bind Decl Expr Binds);" ;;

let ds_rules =
  parse_ds_rules_s "example_desugaring"
    "rule (Let bs b)
       => (DsLet bs b (End) (End))
     rule (DsLet (Bind x defn bs) body params args)
       => (DsLet bs body (Param x params) (Arg defn args))
     rule (DsLet (End) body params args)
       => (Apply (Lambda params body) args)";;

let gram_let =
  parse_grammar_s "let_grammar"
    "Lit = VALUE;
     Decl = VARIABLE;
     Expr = VARIABLE
          | (Num Lit)
          | (Let Decl Type Expr Expr)
          | (Or Expr Expr)
          | (If Expr Expr Expr)
          | (Lambda Decl Type Expr)
          | (Apply Expr Expr);
     Judge = (Judge Ctx Expr Type);
     Ctx = (CtxEmpty)
         | (CtxCons Decl Type Ctx);
     Type = (TNum)
          | (TBool)
          | (TFun Type Type);";;

let ds_let =
  parse_ds_rules_s "let_desugaring"
    "rule (Let y t a b)
       => (Apply (Lambda y t b) a)
     rule (Or a b)
       => (Let X (TBool) a (If X X b))";;

let judge_let =
  parse_inference_rules_s "let_inference_rules"
    "rule x: s, g |- e : t
       => g |- (Lambda x s e) : (TFun s t)
     rule g |- f : (TFun s t)
          g |- e : s
       => g |- (Apply f e) : t
     rule g |- a : (TBool)
          g |- b : t
          g |- c : t
       => g |- (If a b c) : t
     rule
       => x: t, g |- x : t
     ";;
  
let test_infer (ds: rule) (rs: inference_rule list): bool =
  match ds with
  | Rule(lhs, rhs) ->
     let j = generic_judgment (opacify_context rhs) in
     let deriv = infer rs j in
     Printf.printf "\nInferred:\n%s\n" (show_derivation deriv);
     true;;

let test_resugar (ds: rule list) (rs: inference_rule list): bool =
  let derivs = resugar rs ds in
  Printf.printf "\nResugared:\n";
  List.iter (fun d -> Printf.printf "%s\n" (show_derivation d)) derivs;
  true;;
  
  
let test_desugar (t: string) (exp: string): bool =
  let t = parse_term_s "<test>" t in
  let exp = parse_term_s "<test>" exp in
  desugar ds_rules t = exp;;

let test_validate_succ (s: nonterminal) (t: string): bool =
  let t = parse_term_s "<test>" t in
  match validate gram t s with
  | Err _ -> false
  | Ok  _ -> true;;

let test_validate_fail (s: nonterminal) (t: string): bool =
  let t = parse_term_s "<test>" t in
  match validate gram t s with
  | Err _ -> true
  | Ok  _ -> false;;

let tests =
  TestGroup(
      "All Tests",
      [TestGroup(
           "Validation again a Grammar",
           [TestGroup(
                "Atomic",
                [Test("Valid value",
                      fun() -> test_validate_succ "Expr" "(Num '0')");
                 Test("Valid variable",
                      fun() -> test_validate_succ "Expr" "x");
                 Test("Invalid value",
                      fun() -> test_validate_fail "Expr" "(Str '0')")]);
            TestGroup(
                "Terms",
                [Test("Valid",
                      fun() -> test_validate_succ "Expr" "(Let (Bind x (Num '0') (End)) x)");
                 Test("Invalid1",
                      fun() -> test_validate_fail "Expr" "(Let (Bind (Num '0') (Num '0') (End)) x)");
                 Test("Invalid2",
                      fun() -> test_validate_fail "Expr" "(Let (Bind x (Num '0') (End))
                                                               (Bind x (Num '0') (End)))")])]);
       TestGroup(
           "Desugaring",
           [Test("Valid",
                 fun() -> test_desugar
                            "(Let (Bind x (Num '1') (End)) x)"
                            "(Apply (Lambda (Param x (End)) x) (Arg (Num '1') (End)))")]);
       TestGroup(
           "Inference",
           [Test("Let",
                 fun() -> test_resugar ds_let judge_let);
            Test("Let",
                 fun() -> test_infer (List.hd ds_let) judge_let)])]);;
  
run_tests tests;;
