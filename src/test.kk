module test

import std/os/task

/*

TODO: coloring
*/

pub effect test<e>
  fun test(name: string, pred: () -> e bool): ()

pub fun run-test(body: () -> <test<<console|e>>,console|e> ()): <console|e> ()
  var count-ok := 0
  var count-ng := 0
  handle body
    fun test(name, pred)
      print(name)
      if mask<local<_h>>(pred) then
        count-ok := count-ok+1
        println(" OK")
      else
        count-ng := count-ng+1
        println(" NG")
  println("result: " ++ count-ok.show ++ "/" ++ (count-ok + count-ng).show)

// // fun run-test-par(body: () -> <pure,test<pure>> a): <console,pure> a
// pub fun run-test-par(body: () -> <pure,console,test<pure>|e> a): <console,pure|e> a
//   handle body
//     fun test(name, pred)
//       val r = parallel(pred.single)
//       match r.head
//         Nothing -> println(name ++ " ERROR")
//         Just(t) ->
//           if t then
//             println(name ++ " OK")
//           else
//             println(name ++ " NG")
