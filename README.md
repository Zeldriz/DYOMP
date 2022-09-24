#  Do Your Own (M)issions (M)ulti Player

- Create curated custom missions locally on your server (within minutes) and import the missions through missions.db to your production server. The dyomp.fs (filterscript)  will read the .db values and create the custom missions on your server and play out the mission gradually when the player chooses to do it. Nothing needs to added codewise on your production server for managing the missions. There are callbacks provided when a player starts or completes a mission. 

- Required includes: Streamer for streaming objects, pickups, actors. Uses built-in sqlite for storing mission properties.

![missions](preset-images/main.png)



------------


## How it works

- Each mission consists of multiple (no bound on specific number) tasks. Each task can vary from reaching a destination to killing an actor (softsided NPC). On each task completion, player could be rewarded uniquely with a skin, some cash or any weapon. Combining these tasks, complex storyline missions could be created providing enthralling experience for players. Along with custom missions, races and jobs could be created. 
The linear order of mission flow would be:
1. Player starts the mission
2. Mission values from the db get loaded for the player and the first task values
3. Player completes the task
4. Next task gets loaded 
5. Repeat from step 3 until there are no tasks left

![tasks](/preset-images/tasktypes.png)


------------

## Available Mission Properties 

- Choose the way how player starts the mission (checkpoint, phone pickup, talking with an NPC where you can set the dialog lines)
- Set weather when Player starts the mission
- A timer for the player the complete the mission befire it runs out.
- Mapicon for the player to identify the mission location

![Mission_props](/preset-images/missionprops.png)


------------

## Available Task Properties (Applicable for every type of task)

- Set the info message player should be shown when the task starts ex: Find the hidden briefcase around you!
- Set the way info message should be shown (in chat, white textdraw in bottom, right side in a black semi transparent box)
- Mapicon to specify location 
- Specific reward to be given on completion of task

![Task_props](/preset-images/taskprops.png)


------------

## Video Showcase

- [Creating an example mission...](https://youtu.be/8UNPVs4YJrM "Creating an example mission")
- [Result of the Created Mission...](https://youtu.be/Vpf1ONG-0sA "Result of the Created Mission")

## Instructions

- Place the dyomp.amx in your filterscript folder
- Add the dyomp filterscript in your server.cfg

## Where's the local server file to create the mission?

- Since this is a project for automating mission creating process, open sourcing it will make every server which uses this tool become stagnant with same flavour of style of missions.

- I'm willing to negotiate for a price for the full source code and how to set everything up for a server owner so they can fully take advantage of this tool making them unique in their own right among their competitor servers. 

- My discord: dafted punk#3948

- I'll also be in the gta O:MP discord server, you can also find me there.





