CREATE TABLE users (
-- Your required fields
id TEXT PRIMARY KEY,
email TEXT UNIQUE NOT NULL,
password_hash TEXT,
first_name TEXT NOT NULL,
last_name TEXT NOT NULL,
birth_date DATE NOT NULL,

    -- Sleep-specific additions
    timezone TEXT NOT NULL,  -- Critical for sleep timing!

    -- Sleep preferences/goals
    target_sleep_duration INTEGER,  -- minutes (e.g., 480 = 8 hours)
    target_bed_time TEXT,  -- e.g., "22:30"
    target_wake_time TEXT,  -- e.g., "06:30"

    -- Health context (useful for analysis)
    has_sleep_disorder BOOLEAN DEFAULT FALSE,
    sleep_disorder_type TEXT,  -- 'insomnia', 'sleep_apnea', 'restless_legs', etc.
    takes_sleep_medication BOOLEAN DEFAULT FALSE,

    -- Lifestyle factors (can affect sleep)
    occupation_type TEXT,  -- 'shift_work', 'regular_hours', 'flexible', etc.
    caffeine_sensitivity TEXT,  -- 'low', 'medium', 'high'

    -- Preferences
    preferred_unit_system TEXT DEFAULT 'metric',  -- 'metric' or 'imperial'
    language TEXT DEFAULT 'en',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);


I want to remove the default user that is beeing created here database_helper.dart and use a different
way of prepopulating the database pls give me some options on how we can do this.

The habits lab is designed to add an remove modules. So basically it should be a scrolable list that contains
all modules the user wants to adhere to. She can add modules easily by using a plus icon or something
similar like that (maybe a floating button or a button at the end of the list). with this button she can add
one or more modules. important! we need a confirm choices button as well after we have chosen the desiered
modules. then we also need a way to
make individual choices for each module like described in the module specifications. Each module when
chosen the first time, has standard settings but theses can be changed by the user to accomodate for 
specific needs. I imagine it like this: The habits lab initially has a list of all the modules a user
uses atm. Then she can tab on one of the modules that are in use atm (either dubble tab or swipe or
when it gets tabed it shows a gear icon that the user can then tab to get into the next screen where
we can make individual changes to the module that fit the users preferences.
This 1st means we need to store those changes somewhere and 2nd that we need to be forwarded to the
module that the user choose to change. So the habits lab acts as a redirector that (when choosing
to modifiy a habit) redirects us to the modules specific screen. So my questions also is where should
we add/put the individual choices for our modules? should this be something stored globally for the
user or would it work if we store it locally for each module?


1) I would need you advice for this one pls evaluate our current project and then tell me what would
probably be best give me pros an cons for each approach
2) adding a module should activate it immediatly in default mode which can then be modified by the 
user. when removing a module it should definetly keep the data and mark it as an inactive module
therefore removing the notifications (which are part of pretty much all modules)
3) I dont know actually. What do you think you example is exactly the type and length I was thinking
of, but I dont know what would work best for such a case. EAch module should have its unique short
description.
4) About this: I guess it depends on how many shared features each config screen has. If there are many
shared features it would makes sense to have a generic one but I believe each is to unique to do it
like that. The first config screen will be created by us (light module). but later ones might be
implemented by our juniors. (we already have some dedicated plans)
5) Your example looks good maybe take a look at MODULES_PLAN.md and SHARED_README.md and SHARED_PLAN.md
this could also clarify point 4). pls lets explore points 1), 3), 4) and 5) together so we can get
the best solutions.

so for the metadata I'd like you to go for option 3c the new folder