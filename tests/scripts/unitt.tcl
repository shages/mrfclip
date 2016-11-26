package require Tcl 8.5
package provide unitt 1.0
namespace eval unitt {
    namespace export init
    namespace export summarize
    namespace export suite
    namespace export assert_eq
    namespace ensemble create
}

proc unitt::init {} {
  namespace eval ___test {
    variable total_tests
    variable total_errors
    variable msg
    variable err
  }
}

proc unitt::summarize {} {
  puts ""
  if {$___test::total_errors} {
    puts "########    ###    #### ##"
    puts "##         ## ##    ##  ##"
    puts "##        ##   ##   ##  ##"
    puts "######   ##     ##  ##  ##"
    puts "##       #########  ##  ##"
    puts "##       ##     ##  ##  ##"
    puts "##       ##     ## #### ########"
  } else {
    puts "########     ###     ######   ######"
    puts "##     ##   ## ##   ##    ## ##    ##"
    puts "##     ##  ##   ##  ##       ##"
    puts "########  ##     ##  ######   ######"
    puts "##        #########       ##       ##"
    puts "##        ##     ## ##    ## ##    ##"
    puts "##        ##     ##  ######   ######"
  }
  puts ""

  set pass_rate [expr {100 - 100.0*$___test::total_errors/$___test::total_tests}]
  puts "Summary:"
  puts " Total tests: $___test::total_tests"
  puts " Failed tests: $___test::total_errors"
  puts " Pass rate: [format {%.1f%%} $pass_rate]"
}

proc unitt::suite {name tests} {
  puts "######################"
  puts "## Test: $name"
  set count 0
  set errcount 0
  foreach test $tests {
    puts "Running subtest $count..."
    if {[catch {set r [eval $test]} ___test::msg ___test::err]} {
      puts "ERROR: Exception during test: [dict get $___test::err -errorinfo]"
      incr errcount
    }
    #elseif {!$r}
    #  puts "ERROR: Incorrect result for test: $test"
    #  incr errcount
    incr count
  }

  # Record summary
  incr ___test::total_tests $count
  incr ___test::total_errors $errcount

  puts "Summary:"
  puts " Total tests: $count"
  puts " Failed tests: $errcount"
  puts " Pass rate: [format {%.1f%%} [expr {100 - 100.0*$errcount/$count}]]"
  puts ""
  return $errcount
}

proc unitt::assert_eq {a b} {
  if {$a == $b} {
    return 0
  } else {
      # Check for list 
      if {[llength $a] > 1 && [llength $a] == [llength $b]} {
          set fail 0
          for {set i 0} {$i < [llength $a]} {incr i} {
              set A [lindex $a $i]
              set B [lindex $b $i]
              if {$A != $B} {
                  set fail 1
                  break
              }
          }
          if {!$fail} { return 0 }
      }
    puts "ERROR: Not equal:"
    puts " a: $a"
    puts " b: $b"
    error AssertionError
  }
}

