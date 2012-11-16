# Export functions defined here either onto the
# exports object (if we are in node) or onto the global
# intermine.funcutils namespace

IS_NODE = typeof exports isnt 'undefined'
root = exports ? this

if IS_NODE
    {Deferred} = require 'underscore.deferred'
else
    {Deferred} = root.jQuery
    root.intermine ?= {}
    root.intermine.funcutils ?= {}
    root = root.intermine.funcutils

root.error = (e) -> Deferred( -> @reject new Error(e) ).promise()

root.success = (args...) -> Deferred( -> @resolve args... ).promise()

root.fold = (init, f) -> (xs) ->
    if xs.reduce? # arrays
        xs.reduce f, init
    else # objects
        ret = init
        for k, v of xs
           ret = if ret? then f(ret, k, v) else {k: v}
        ret

root.take = (n) -> (xs) -> if n? then xs[0 .. n - 1] else xs

# Until I can find a nicer name for this...
# Basically a mapping over an object, taking a
# function of the form (oldk, oldv) -> [newk, newv]
root.omap = (f) -> (xs) ->
    merger = (a, oldk, oldv) ->
        [newk, newv] = f oldk, oldv
        a[newk] = newv
        return a
    (exports.fold {}, merger) xs

root.copy = root.omap (k, v) -> [k, v]

root.partition = (f) -> (xs) ->
    trues = []
    falses = []
    for x in xs
        if f x
            trues.push x
        else
            falses.push x
    [trues, falses]

# Implementation of concatmap.
#
# This a function that applies a function to each member
# of an array, and combines the results through the natural
# method of combination. Arrays are concatenated, and strings
# are, well, concatenated. Objects are merged.
#
# @param f The function to apply to each item.
# @param xs The things to apply them to.
root.concatMap = (f) -> (xs) ->
    ret = undefined
    for x in xs
        fx = f x
        ret = if ret is undefined
            fx
        else if typeof fx in ['string', 'number']
            ret + fx
        else if fx.slice?
            ret.concat(fx)
        else
            ret[k] = v for k, v of fx
            ret
    ret

root.flatMap = root.concatMap

root.sum = root.concatMap ->

root.AND = (a, b) -> a and b

root.OR = (a, b) -> a or b

root.NOT = (x) -> not x

# The identity function
#
# @param x Something
# @return The self same thing.
root.id = id = (x) -> x

root.any = (xs, f = id) ->
    for x in xs
        return true if f x

# A set of functions that are helpful when dealing with promises,
# in that they help produce the kinds of simple pipes that are
# frequently used as callbacks.

# Get a function that invokes a named method
# on an object of type A.
# 
# @param [String] name The name of a method
# @param [Array] args An optional argument list, passed as varargs
# @return [(obj) -> ?] A function that invokes a named method.
root.invoke = (name, args...) -> (obj) ->
    if obj[name]?.apply
        obj[name].apply(obj, args)
    else
        Deferred().reject("No method: #{ name }").promise()

# Get a function that invokes a method on an object
# that is passed to it with the arguments given here, with
# an optional binding for this.
#
# This function differs from invoke in that it expects the optional
# argument list to be passed in an Array, rather than as separate
# elements in the argument list.
#
# @param [String] name The name of the method
# @param [Array] args The arguments to the method
# @param [Object] ctx The value for this in the invocation (optional)
# @return [(obj) -> ?] A function that invokes a named method.
root.invokeWith = (name, args = [], ctx = null) -> (o) -> o[name].apply((ctx or o), args)

# Get a function that gets a named property off an object.
#
# @param [String] name the name of the property
# @return [(obj) -> ?] A function that gets a property's value.
root.get = (name) -> (obj) -> obj[name]

# Get a function that sets a named property, or set of properties
# on an object, returning the new state of the object.
#
# @example
#   promise.then(set('name', 'Anne'))
#   promise.then(set({name: 'Bill', age: 43}))
#
# @param [String|Object] name the name of the property, or an object of
#   properties to set.
# @param [?] value The value to set (optional).
# @return [(obj) -> ?] A function that sets a property's value, and returns the object.
root.set = (name, value) -> (obj) ->
    if arguments.length is 2
        obj[name] = value
    else
        for own k, v of name
            obj[k] = v
    return obj

