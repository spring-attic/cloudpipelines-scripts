# Dummy function
dummy() { : }
# Test1 function
test1() { echo "Hello"; test2; () { test6; a() { : } } }

# Test2 function
test2() {
    echo "Hello"
    test3
}

# Test3 function
function test3 { echo "Hello"; test4; }
# Test4 function
function test4() { echo "Hello"; test5; }

# Test5 function
function test5 {
    echo "Hello"
    test6
    function test5sub() {
        echo Hello2
    }
    test5sub2() {
        echo Hello2
    }
}
# Test6 function
function test6() {
    echo "Hello"
    dummy
}

() {
    anonSub() { echo Hello2; }
    () { echo Hello2; }
}
