Random design ramblings about CorsixTH
======================================
Everything below is just random ideas and thoughts. It's missing crucial parts,
fails to take some cases into consideration, and will probably fail to work
completely currently.

In other words, this is very much WIP, please find flaws and omissions in it,
to improve the design.


Current implementation
----------------------
The current design pushes tick calls from the world/app to everything that
needs to update itself based on time. The UI hooks into calls for delivering
user actions to the objects. Behaviour of entities is expressed in the action
queue by "(humanoid) actions" classes, often linking several entities together
for synchronized execution (eg a treatment animation). This linking also
happens asynchronously, eg a doctor and a patient both walking to a room for
examination or treatment.

All this leads to big complexity problems. Within a single entity, loads of
variables are used to express the state without clear meaning and scope. Events
lead to rewrites in the action queu(s) of entities, or systems on top of that,
like the call dispatcher and handyman tasks queue.

At a higher level, there is little to no structure to handle synchronization.
(In particular with respect to premature ending due to events like patients
dying, doctors getting fired, and so on.) There is also not much code for
making or handling more global decisions (except for very high global systems
like the call dispatchers).


Entity improvements
-------------------
The entire system is event-based from the perspective of an entity. It gets
callbacks when time has passed, the user pressed a button, and so on. Due to
the programming language, each time it has to inspect its state, consider the
event that happened, and act on it.

Unfortunately, entities are not trivial. They often have several mostly
independent parts that just happen to live in a single entity. For example,
the plant in CorsixTH does

* "Eat" water daily, and slowly die.
* Warn the handyman to give water when it is running low.
* Handle being unreachable for the handyman.
* Handle updating the handyman request with updating priority of the call.
* Handle restoring to full health after getting water by the handyman.
* Warn the user when severely lacking water.
* Handle getting picked up and placed at another spot by the user.

and this is just a plant, which doesn't actually move at all in the game.
Other entities are likely at least this complicated.


To combat this complexity, you need to have a better definition of state. The
code should handle jumping to the point where you left off the last time, and
give a unified interface to make decisions. You also need to be able to
express independent parts as independent. The intended solution is to have a
set of finite state machines (one FSM for each part), and have very restricted
setup of "event_name" + "condition holds" means "do action, and go to new
state".
Since it is likely the state machines will share things, the biggest danger
here is that different FSMs may still inspect state of the other parts (which is not
necessarily a problem), or write into data of other parts (!).

If this is considered to be a problem (which may not be a bad idea), one could
use a separate object for each part, making it at least explicit when
accessing variables that you don't own.


Global synchronization management
=================================
In my view, the biggest issue is in how to match up entities that will
synchronize with each other in an animation in a room. In this document, such
a synchronization is called an "activity". Generally, there is one central
activity that everybody participates in, and some other activities that
involve only a few entities before and/or after it. In some cases, there can
be quite long sequences.

Currently such sequences are hard-coded in the actions (I think), and then
pushed into the action queues of the entities. If something then runs wrong
along the way, reverting to a known sane state is non-trivial.

So instead, I believe the entities themselves should track their own state
with respect to the room activities. This is quite easy to do with an
additional fsm. When they engage in an activity they change state, so only
other activities can be performed next. If something runs wrong, the state
will be able to decide how to proceed, for example towards leaving the room
by dressing first. The room can be simplified to just offering
activities, matching up entities for activities.

Unsolved puzzles (input appreciated):
1. How to prevent people from walking in at unwanted times? (While treatment
   is going on, second patient enters the room, but cannot disrobe as the
   screen doesn't allow it)
2. How to get eg surgeons to wait in operating clothes?
3. How to handle people that have not yet arrived (doctor and patient both
   heading for the same room, then doctor is called, or patient dies, etc).
4. Can patient or doctor first do other things before getting there (resting,
   getting a drink, going to the toilet)?
5. How to deal with unexpected people walking in? (or getting dropped). In the
   former case it feels like a program error, at least.

A seemingly quite feasible solution could be that the room has a list ongoing
activities that it monitors for finishing. It should also monitor people
entering (and leaving), as well as user editing the room, and picking up
people. It should be able to reach conclusions about what is available for
next activities.

      Important notion here is that user interaction (eg user firing a
      doctor, or editing a room, or adding an object) should be handled
      and agreed by all entities involved (thus keeping things in sync
      when they happen).

An "ongoing activity" can also act as a communication point to all involved
(eg "please abort, doctor is being replaced").

Unsolved puzzles (input appreciated):
10. Replacing staff is still a problem, how to select activities that make the
    new staff member arrive at the state where the discharged staff member
    left off? (it seems to suggest that the activities connect with each other
    in some way, so a path search from current entity state to desired state
    can be performed.)

11. How to deal with the classroom, where staff randomly walks in and out
    while there is a lecture (possible solution is not to see it as a single
    activity?)
12. Similarly, the ward with several patients entering and leaving, while the
    nurse should be able to leave if she is tired (thus prevent more patients
    from walking in?).

13. What about all the "outside-room" activities? (Which ones exist, how to
    handle them?)

.. vim: tw=78 spell
