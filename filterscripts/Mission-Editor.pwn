#include <a_samp>

#include <streamer>

#include <izcmd>

#include <sscanf2>

#include <mselect>


		
#define MISSION_PASSWORD_LEN	30

#define MAX_START_DIALOGS	5

#define HELP_MSG_COLOR 0x00FF00FF

#define GROUP_MSG_COLOR 0xFFFF00FF

#define MAX_MISSIONS	100

#define MAX_TASKS		50

//=====================================================


#define SHOW_DIALOG_MISSION_VARS		0

#define SHOW_DIALOG_TASK_TYPE			1

#define SHOW_DIALOG_MVAR_INPUT			2

#define SHOW_DIALOG_TASK_VARS			3

#define SHOW_DIALOG_TASK_VARS_INPUT		4

#define SHOW_DIALOG_WEP_LIST 			5


//=====================================================

//mission info dialog list items.

#define MV_TIMEAMOUNT	0

#define MV_WEATHER		1

#define MV_MAP_ICON		2

#define MV_START_TYPE	3

#define MV_START_INFO	4

#define MV_START_ACTOR_ID	5

#define MV_CREATE_TASK	6

#define MV_DELETE_LAST_CREATED_TASK	7

#define MV_FINISH		8


//=====================================================
//task types

#define TASK_ARRIVE_DEST		0

#define TASK_FIND_OBJ 			1

#define TASK_ENTER_HIDDEN_VEH 	2	

#define TASK_FIND_HIDDEN_OBJ	3

#define TASK_ENTER_VEH 			4

#define TASK_TAKE_VEH_TO_DEST	5

#define TASK_GOTO_ACTOR			6

#define TASK_TALK_TO_ACTOR		7

#define TASK_KILL_ACTOR			8


//=====================================================
//task var defines
#define taskinfo 0
#define infostyle 1
#define vehid 2
#define objid 3
#define mapobjid 4 
#define setactordialog 5
#define rewardwep 6
#define rewardskin 7
#define rewardcash 8
#define finishTask 9


//Password to access making missions.....
new  MISSION_PASSWORD[MISSION_PASSWORD_LEN] = "mypass";


//to add new task var, add define, add in dialog list, add case in SetVarforTaskRow same for mission vars


static DB: MissionHandler;


//textdraws to shwo what mission and task admin is currently making....
new Text: TextMName;

new Text: TextTInfo;


enum MISSION_VARS{ 

	MNAME[24],
	TASK_NUMBER, //to see on which task number player is editing on 
	TASK_TYPE,
	HAS_ACCESS_TO_EDIT_MISSIONS,
	ChosenListItem,


}


//Each player can at once edit one mission, we store values in this array and use it to update db...
new mission_vars[MAX_PLAYERS][MISSION_VARS]; 


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************



/*=====================================================

For menu lists of vehicles, pickups and marker icons

We delay each menu showing for few ms because double clicking on an option from a dialog
and showing a menu immediately closes the menu, the second click acts as clicking on a box in the menu inside...

=====================================================*/

#define Timer_Vehicle_Menu			0

#define Timer_Mission_Skin_Menu		1

#define Timer_Task_Skin_Menu 		2

#define Timer_Task_Reward_Skin_Menu	3

#define Timer_Mission_MapIcons_Menu	4

#define Timer_Task_MapIcons_Menu	5

#define Timer_Pickups_Menu			6

#define Timer_Wait_To_Show_Menu_Time	500

forward WaitOneSecToShowMenu(playerid,Menu_ID);

public WaitOneSecToShowMenu(playerid,Menu_ID)
{
    switch(Menu_ID)
    {
    	case Timer_Vehicle_Menu:
    	{
            MSelect_Show(playerid, MSelect:Vehicle_menu);

    	}

    	case Timer_Mission_Skin_Menu:
    	{
    	   MSelect_Show(playerid, MSelect:Mission_Skin_Menu);
	
    	}

    	case Timer_Task_Skin_Menu:
    	{
    		MSelect_Show(playerid, MSelect:Task_Skin_Menu);

    	}

    	case Timer_Task_Reward_Skin_Menu:
    	{
    		
    	   MSelect_Show(playerid, MSelect:Task_Reward_Skin_Menu);

        }
    	case Timer_Mission_MapIcons_Menu:
    	{
    		MSelect_Show(playerid, MSelect:Mission_MapIcons_Menu);
    	}

    	case Timer_Task_MapIcons_Menu:
    	{
    		MSelect_Show(playerid, MSelect:Task_MapIcons_Menu);

    	}

    	case Timer_Pickups_Menu:
    	{
    		MSelect_Show(playerid, MSelect:Pickups_Menu);
    	}
    }
    return 1;
}


MSelectCreate:Vehicle_menu(playerid)
{
	static
		items_array[212] = {MSELECT_INVALID_MODEL_ID, ...};

	if (items_array[0] == MSELECT_INVALID_MODEL_ID) 
	{
		for (new i = 0; i < sizeof(items_array); i++) 
		{
			items_array[i] = i+400;
		}
	}

	MSelect_Open(playerid, MSelect:Vehicle_menu, items_array, sizeof(items_array),.rot_x = 45.0, .header = "Vehicle Menu");
}

MSelectCreate:Mission_Skin_Menu(playerid)
{
	static
		items_array[312] = {MSELECT_INVALID_MODEL_ID, ...};

	if (items_array[0] == MSELECT_INVALID_MODEL_ID) 
	{
		for (new i = 0; i < sizeof(items_array); i++) 
		{
			items_array[i] = i;
			
		}
	}

	MSelect_Open(playerid, MSelect:Mission_Skin_Menu, items_array, sizeof(items_array), .header = "Skin Menu");
}

MSelectCreate:Task_Skin_Menu(playerid)
{
	static
		items_array[312] = {MSELECT_INVALID_MODEL_ID, ...};

	if (items_array[0] == MSELECT_INVALID_MODEL_ID) 
	{
		for (new i = 0; i < sizeof(items_array); i++) 
		{
			items_array[i] = i;
			
		}
	}

	MSelect_Open(playerid, MSelect:Task_Skin_Menu, items_array, sizeof(items_array), .header = "Skin Menu");
}

MSelectCreate:Task_Reward_Skin_Menu(playerid)
{
	static
		items_array[312] = {MSELECT_INVALID_MODEL_ID, ...};

	if (items_array[0] == MSELECT_INVALID_MODEL_ID) 
	{
		for (new i = 0; i < sizeof(items_array); i++) 
		{
			items_array[i] = i;
			
		}
	}

	MSelect_Open(playerid, MSelect:Task_Skin_Menu, items_array, sizeof(items_array), .header = "Skin Menu");
}



MSelectCreate:Mission_MapIcons_Menu(playerid)
{ //use itemid + 2
	static
		items_array[62] = {MSELECT_INVALID_MODEL_ID, ...};

	if (items_array[0] == MSELECT_INVALID_MODEL_ID) 
	{
		for (new i = 0; i < sizeof(items_array); i++) 
		{
			items_array[i] = i+19202;
		}
	}

	MSelect_Open(playerid, MSelect:Mission_MapIcons_Menu, items_array, sizeof(items_array), .header = "MapIcon Menu", .rot_x = 90.0, .rot_y = 180.0, .item_width = 70.0,.item_height = 80.0);
}


MSelectCreate:Pickups_Menu(playerid)
{
	static
		items_array[] = {954,1210,1212,1213,1239,1240,1241,1242,1247,1248,1252,1253,1254,1272,1273,1274,1275,1276,1277,1279,1310,1313,1314,1318, 
						1550,1575,1576,1577,1578,1579,1580,1581,1582,1636,1644,1650,1654,1672,2033,2034,2035,2036,2037,2044,2045,2057,2058,2059,
						2060,2061,2064,2068,2228,2237,2690,2709,2710,11731,11736,11738,18631,19054,19055,19056,19057,19058,19130,19131,19132,19133,
						19134,19135,19197,19198,19320,19522,19523,19524,19602,19605,19606,19607,19832,2886,2976,2977,3786,3790,918,1217,1218,1222,
						1225,1554,1558,3056,1985,2705,2706,902};


	MSelect_Open(playerid, MSelect:Pickups_Menu, items_array, sizeof(items_array),.rot_y = 45.0, .header = "Pickup Menu");
}


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************


/*=====================================================

invoke all necessary items in the init callback...

=====================================================*/
public OnFilterScriptInit()
{

	//Reset player vars used for making missions...
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		ResetVars(i);
	}

	//make connection to the db...
	MissionHandler = db_open("DYOMP.db");

	if(MissionHandler)
	{
		printf("~~Connection to Missions database was succesfull!~~");
		
		CreateMissionTable();
					
	}
	else
	{
		printf("~~Failed to make connection to Missions database!~~");
	}
	
	//Textdraws used to show mission and task type info when making missions...
	TextMName = TextDrawCreate(326.000000, 369.000000, " ");
	TextDrawAlignment(TextMName, 2);
	TextDrawBackgroundColor(TextMName, 255);
	TextDrawFont(TextMName, 1);
	TextDrawLetterSize(TextMName, 0.310000, 2.499999);
	TextDrawColor(TextMName, -1);
	TextDrawSetOutline(TextMName, 0);
	TextDrawSetProportional(TextMName, 1);
	TextDrawSetShadow(TextMName, 2);
	TextDrawSetSelectable(TextMName, 0);


	TextTInfo = TextDrawCreate(442.000000, 160.000000, " ");
	TextDrawBackgroundColor(TextTInfo, 255);
	TextDrawFont(TextTInfo, 1);
	TextDrawLetterSize(TextTInfo, 0.500000, 1.899999);
	TextDrawColor(TextTInfo, -1);
	TextDrawSetOutline(TextTInfo, 1);
	TextDrawSetProportional(TextTInfo, 1);
	TextDrawUseBox(TextTInfo, 1);
	TextDrawBoxColor(TextTInfo, 199);
	TextDrawTextSize(TextTInfo, 600.000000, 396.000000);
	TextDrawSetSelectable(TextTInfo, 0);

	return 1;
}


public OnFilterScriptExit()
{
	db_close(MissionHandler);

	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		ResetVars(i);
	}
	return 1;
}


public OnPlayerDeath(playerid)
{
	//If player was in process of making a mission during death....remove that mission info in db and reload all missions
	if(mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 1)
	{
		new query[60];
	
		format(query, sizeof query, "DROP TABLE IF EXISTS '%s' ", mission_vars[playerid][MNAME]);

		db_query(MissionHandler, query);
	
		format(query, sizeof query, "DELETE FROM `mission_vars` WHERE `name` = '%s' ",  mission_vars[playerid][MNAME]);
	
		db_query(MissionHandler,query);

		CallRemoteFunction("LoadAllMissionPoints","");	
		
		SendClientMessage(playerid,HELP_MSG_COLOR,"You died while making a mission, the mission has been erased! Please make it again.");

		ResetVars(playerid);
	}
	
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{

	//If player was in process of making a mission during death....remove that mission info in db and reload all missions
	if(mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 1)
	{
		new query[60];
	
		format(query, sizeof query, "DROP TABLE IF EXISTS '%s' ", mission_vars[playerid][MNAME]);

		db_query(MissionHandler, query);
	
		format(query, sizeof query, "DELETE FROM `mission_vars` WHERE `name` = '%s' ",  mission_vars[playerid][MNAME]);
	
		db_query(MissionHandler,query);

		CallRemoteFunction("LoadAllMissionPoints","");	
		
		ResetVars(playerid);

	}

	return 1;
}


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************


/*=====================================================

**| make connection to db of missionnames.
**| store values for mission and task vars enterd by mission maker
**| create necessary dialogs to take vars inputs
**| on input fill the db appropriately

=====================================================*/


ResetVars(playerid)
{
	mission_vars[playerid][TASK_TYPE] = 0;
	mission_vars[playerid][TASK_NUMBER] = 0;
	//mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] = 0;
	mission_vars[playerid][ChosenListItem] = 0;
}


SelectMissionVar(playerid,list_item) //used after player selects one item in mission dialog
{
	mission_vars[playerid][ChosenListItem] = list_item;

	ShowRelevantDialog(playerid,SHOW_DIALOG_MVAR_INPUT); //now we take input from player and load it using below function setvalintomissiondb...

}

SetValIntoMissionDB(playerid,inputtext[]) 
{
	/**
	 * When player is show the main mission making dialog...
	 * He chooses an item for which input is required...
	 * We use SelectMissionVar for remembering which item chosen in main mission dialog...
	 * We take input of that item and update values using this function
	 */

	new InputAmount = strval(inputtext);
	switch(mission_vars[playerid][ChosenListItem])
	{
		//set inputtext into appropriate column based on case

		case MV_TIMEAMOUNT:
		{

			new query[100];

			format(query, sizeof query, "UPDATE `mission_vars` SET `timeamount` = %d WHERE name = '%s' ", InputAmount, mission_vars[playerid][MNAME]);
			db_free_result(db_query(MissionHandler,query));

			ShowRelevantDialog(0,SHOW_DIALOG_MISSION_VARS);

		}
		case MV_START_TYPE:
		{
			new query[100];

			format(query, sizeof query, "UPDATE `mission_vars` SET `starttype` = %d WHERE name = '%s' ", InputAmount, mission_vars[playerid][MNAME]);


			db_free_result(db_query(MissionHandler,query));

			ShowRelevantDialog(0,SHOW_DIALOG_MISSION_VARS);
		}
		case MV_WEATHER:
		{
			new query[100];

			format(query, sizeof query, "UPDATE `mission_vars` SET `weather` = %d WHERE name = '%s' ", InputAmount, mission_vars[playerid][MNAME]);

			db_free_result(db_query(MissionHandler,query));

			ShowRelevantDialog(0,SHOW_DIALOG_MISSION_VARS);
		}
	}
}



SetValIntoTaskRow(playerid,inputtext[]) //after value is inputted in task var dialogs
{
	/**
	 * When player is show the task making dialog...
	 * He chooses an item for which input is required...
	 * We use mission_vars[playerid][ChosenListItem] for remembering which item chosen in main task making dialog...
	 * We take input of that item and update values using this function
	 */
	new Amount = strval(inputtext);
	switch(mission_vars[playerid][ChosenListItem])
	{
		case taskinfo:
		{
			new query[300];

			format(query, sizeof query, " UPDATE `%s` SET `taskinfo` = '%s' WHERE `taskid` = %d", mission_vars[playerid][MNAME], inputtext,mission_vars[playerid][TASK_NUMBER]);
			db_free_result(db_query(MissionHandler,query));

			ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
		}
		case infostyle:
		{

			new query[300];

			format(query, sizeof query, " UPDATE `%s` SET `infostyle` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], Amount,mission_vars[playerid][TASK_NUMBER]);
			db_free_result(db_query(MissionHandler,query));

			ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);

		}
		case rewardcash:
		{
			new query[300];

			format(query, sizeof query, " UPDATE `%s` SET `rewardcash` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], Amount,mission_vars[playerid][TASK_NUMBER]);
			db_free_result(db_query(MissionHandler,query));
			ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
		} 
		
	}
	
}

                                                                                                 
CreateMissionTable() //used when /create is used 
{
	//main mission table which stores every mission meta info...
	db_free_result( db_query(MissionHandler,"CREATE TABLE IF NOT EXISTS `mission_vars` (name VARCHAR(24) PRIMARY KEY, numtasks INTEGER,mapicon INTEGER,start_x REAL, start_y REAL, start_z REAL,actrot REAL, timeamount INTEGER, weather INTEGER, starttype INTEGER,actorid INTEGER, dialog_1 VARCHAR(100),dialog_2 VARCHAR(100),dialog_3 VARCHAR(100),dialog_4 VARCHAR(100),dialog_5 VARCHAR(100),group_name VARCHAR(20) default value NULL,grp_msn_sequence INT default value NULL)") );

	//to store player group count relationship...
	db_free_result( db_query(MissionHandler,"CREATE TABLE IF NOT EXISTS `Player_Group_Relation` (PlayerName VARCHAR(24),group_name VARCHAR(20),grp_msn_sequence INT)") );

}


CreateTask(playerid,task_type) //after a task type is selected from task type dialog box --> MV_CREATE_TASK
{
	mission_vars[playerid][TASK_TYPE] = task_type;
	mission_vars[playerid][TASK_NUMBER] += 1;
	new query[100];
	format(query, sizeof query, "UPDATE `mission_vars` SET `numtasks` = %d WHERE name = '%s' ", mission_vars[playerid][TASK_NUMBER],mission_vars[playerid][MNAME]);
	db_free_result(db_query(MissionHandler,query));

	format(query, sizeof query, "INSERT INTO `%s` (`tasktype`) VALUES (%d) ", mission_vars[playerid][MNAME],mission_vars[playerid][TASK_TYPE]);

	db_free_result(db_query(MissionHandler,query));

	//increase tasknum in main mission table
	//use mission_vars[playerid][task_number] to insert relevant data in task table
	new info[1000];
	switch(mission_vars[playerid][TASK_TYPE])
	{
		case TASK_ARRIVE_DEST:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ mapicon",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);
			
			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} mapicon");
		}
		case TASK_FIND_OBJ:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ mapicon,objid",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} mapicon,objid,mapicon");

		}
		case TASK_ENTER_HIDDEN_VEH:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ vehid",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} vehid, {FFF000} NOTE: next task should be destination type!");

		}
		case TASK_ENTER_VEH:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ mapicon,vehid ~p~ NOTE: next task should be destination type!",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} mapicon,vehid");
		}
		case TASK_FIND_HIDDEN_OBJ:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ objid",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} objid");

		}
		case TASK_TAKE_VEH_TO_DEST:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set vars: ~y~ mapicon",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} mapicon");

		}
		case TASK_TALK_TO_ACTOR:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set: ~y~ actorid through objid,mapicon,dialog strings",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} actorid through objid,mapicon,dialog strings");

		}
		case TASK_GOTO_ACTOR,TASK_KILL_ACTOR:
		{
			format(info, sizeof info," Task Type: ~y~ %d \n ~w~ Task Num: ~y~ %d \n ~w~ Need to set: ~y~ actorid through objid,mapicon",mission_vars[playerid][TASK_TYPE],mission_vars[playerid][TASK_NUMBER]);

			SendClientMessage(playerid,HELP_MSG_COLOR,"Need to set: {00F000} actorid through objid,mapicon");

		}
	}

	TextDrawSetString(TextTInfo, info);
	TextDrawShowForPlayer(playerid, TextTInfo);
	SendClientMessage(playerid,HELP_MSG_COLOR,"Goto required position and use {FFF000} /setpos");
	
}


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************



/*=====================================================

When admin wants to edit,create, delete missions; he needs to get access through password...

=====================================================*/


/**
 * /makemissions --> For gaining access to start making missions
 * /create --> create a mission
 * /showmis --> Show All created missions
 * /delmis --> Delete a mission in the system 
 */ 



CMD:makemissions(playerid,params[])
{
	new PasswordInputByPlayer[MISSION_PASSWORD_LEN];
	if(!sscanf(params,"s[50]",PasswordInputByPlayer))
	{
		if(strcmp(MISSION_PASSWORD,PasswordInputByPlayer) == 0 && mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 0)
		{
			SendClientMessage(playerid,HELP_MSG_COLOR,"Right password!, start making missions using /create [mission name]");

			OnPlayerEnterMissionMakingMode(playerid);

			mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] = 1;
		}
		else if (strcmp(MISSION_PASSWORD,PasswordInputByPlayer) == 0 && mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 1)
		{
			SendClientMessage(playerid,HELP_MSG_COLOR,"Exited Mission Making Mode!");	

			mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] = 0;

			OnPlayerExitMissionMakingMode(playerid);
			ResetVars(playerid);

		}
		else if (strcmp(MISSION_PASSWORD,PasswordInputByPlayer) != 0 && mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 0)
		{
			SendClientMessage(playerid,HELP_MSG_COLOR,"ERROR: Wrong Password, Please try again or check with dev if you have the right password!");	

			mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] = 0;
		}
		else if (strcmp(MISSION_PASSWORD,PasswordInputByPlayer) != 0 && mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 1)
		{
			SendClientMessage(playerid,HELP_MSG_COLOR,"ERROR: Wrong state of usage of this command, you already are in mission making mode!");	

			mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] = 0;
		}
	}
	else
	{
		SendClientMessage(playerid,HELP_MSG_COLOR,"ERROR:Enter correct password format(string)!");
	}
	return 1;
}

/*=====================================================

When admin needs to set position for relevant entity when making a task...

=====================================================*/

CMD:setpos(playerid,params[]) //to set post into db
{
	//take the pos value into task posx posy posz
	//now show dialog to take task info 
		new Float:posx, Float:posy, Float:posz;
		GetPlayerPos(playerid, Float:posx, Float:posy, Float:posz);
	
		new query[300];
		new Float: rot;
		GetPlayerFacingAngle(playerid, rot);

		format(query, sizeof query, " UPDATE `%s` SET `posx` = %f,`posy` = %f,`posz` = %f, `rot` = %f WHERE `taskid` = %d", mission_vars[playerid][MNAME], posx, posy, posz,rot,mission_vars[playerid][TASK_NUMBER]);
	
		db_free_result(db_query(MissionHandler,query));

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
	
		SendClientMessage(playerid,HELP_MSG_COLOR,"Position set succesfuully!");

}

/*=====================================================

important: Main cmd used to create missions....

=====================================================*/


CMD:create(playerid,params[]) //called to initialise a new mission sequence
{

		OnPlayerStartCreatingMission(playerid);
		new Float:posx,posy,posz,rot;
		GetPlayerPos(playerid,Float:posx,Float:posy,Float:posz);
		GetPlayerFacingAngle(playerid, Float:rot);
		
		if(!sscanf(params,"s[24]",mission_vars[playerid][MNAME]))
		{
			new query[500];
	
			format(query, sizeof(query),"CREATE TABLE IF NOT EXISTS `%s` (`taskid` INTEGER PRIMARY KEY,`tasktype` INTEGER, `taskinfo` VARCHAR(100), `infostyle` INTEGER, `posx` REAL, `posy` REAL, `posz` REAL,`vehid` INTEGER, `objid` INTEGER, `mapobjid` INTEGER,`rot` REAL,`dialog_1` VARCHAR(100), `dialog_2` VARCHAR(100),`dialog_3` VARCHAR(100),`dialog_4` VARCHAR(100),`dialog_5` VARCHAR(100), `rewardwep` INTEGER, `rewardskin` INTEGER, `rewardcash` INTEGER )" , mission_vars[playerid][MNAME]);
			
			db_free_result(db_query(MissionHandler,query) );
	
			new insert_query[300];
	
			format(insert_query,sizeof(insert_query),"INSERT INTO `mission_vars` (name) VALUES ('%s')",mission_vars[playerid][MNAME]);
	
			db_free_result(db_query(MissionHandler,insert_query) );
	
			format(insert_query,sizeof insert_query, "UPDATE `mission_vars` SET `start_x` = %f,`start_y` = %f,`start_z` = %f ,`actrot` = %f WHERE `name` = '%s' ",posx,posy,posz,rot,mission_vars[playerid][MNAME]);
			
			db_free_result(db_query(MissionHandler,insert_query) );
	
			new info[40];
	
			format(info, sizeof info, "MISSION NAME : ~y~ %s", mission_vars[playerid][MNAME]);
	
			TextDrawSetString(TextMName, info);
	
			TextDrawShowForPlayer(playerid, TextMName);
	
	
			ShowRelevantDialog(playerid,SHOW_DIALOG_MISSION_VARS);
	
			SendClientMessage(playerid, HELP_MSG_COLOR, "Executed Succesfully!");
			
		}
		else
		{
			SendClientMessage(playerid, HELP_MSG_COLOR,"Invalid Mission name, use proper format!");
		}

		return 1; 
}

/*=====================================================

When admin wants to set convo for player...

=====================================================*/
CMD:dialog(playerid,params[])
{

		new dialog[100];
		new count;
		if(sscanf(params,"is[100]",count,dialog))
		{
	
			SendClientMessage(playerid, HELP_MSG_COLOR,"{FFF000} Format: /dialog [1-5] [text]");
			return 1;      
	
		}
		else
		{
			new DialogPos[10]; 
			new insert[100];
			format(DialogPos, sizeof DialogPos, "dialog_%d",count);
			SendClientMessage(0,HELP_MSG_COLOR,DialogPos);
	
			if(count > MAX_START_DIALOGS) //invalid position for dialog
			{
				SendClientMessage(0,HELP_MSG_COLOR,"Invalid place to set dialog inside!");
				ShowRelevantDialog(0,SHOW_DIALOG_MISSION_VARS);		
    	 	}
			else
			{					
				format(insert, sizeof insert, "UPDATE `mission_vars` SET `%s` = '%s' WHERE name = '%s' ",DialogPos,dialog, mission_vars[playerid][MNAME]);
				new info[150];
				format(info,sizeof info,"dialog set into dialog_%d with the msg: %s ",count,dialog);
				SendClientMessage(0,HELP_MSG_COLOR,info);
				db_free_result(db_query(MissionHandler,insert));
				ShowRelevantDialog(0,SHOW_DIALOG_MISSION_VARS);
			}
		}
		return 1;

}

/*=====================================================

When admin wants to set dialog convo for npc when making mission relevant to them...

=====================================================*/
CMD:actdialog(playerid,params[])
{

		new dialog[100];
		new count;
		if(sscanf(params,"is[100]",count,dialog))
		{
			SendClientMessage(playerid, HELP_MSG_COLOR,"{FFF000} Format: /dialog [1-5] [text]");
			return 1; 	       
	
		}
		else
		{
			new text[10]; 
			new insert[100];
			format(text, sizeof text, "dialog_%d",count);
			SendClientMessage(0,HELP_MSG_COLOR,text);
	
			if(count > MAX_START_DIALOGS)
			{
					SendClientMessage(0,HELP_MSG_COLOR,"Invalid place to set dialog inside!");
					ShowRelevantDialog(0,SHOW_DIALOG_TASK_VARS);
			
    	 	}
			else
			{
							
				format(insert, sizeof insert, "UPDATE `%s` SET `%s` = '%s' WHERE taskid = %d ",mission_vars[playerid][MNAME], text,dialog, mission_vars[playerid][TASK_NUMBER]);
				new info[150];
				format(info,sizeof info,"dialog set into actdialog_%d with the msg: %s ",count,dialog);
				SendClientMessage(0,HELP_MSG_COLOR,info);
				db_free_result(db_query(MissionHandler,insert) );
				ShowRelevantDialog(0,SHOW_DIALOG_TASK_VARS);
			}  
		}

		return 1;

}

/*=====================================================

When admins wants to see existing missions list...

=====================================================*/
CMD:showmis(playerid,params[])
{

		new DBResult: db_result = db_query(MissionHandler,"SELECT `name` FROM `mission_vars`");
	
		new name[24];
	
		if(db_num_rows(db_result) > 0 )
		{
			do
			{
	
				db_get_field_assoc(db_result,"name", name, 24);
	
				SendClientMessage(playerid, HELP_MSG_COLOR, name);
			}
			while(db_next_row(db_result));
	
			SendClientMessage(playerid, HELP_MSG_COLOR, "{FFF000} Use /delmis [Mission Name] to delete any missions");
	
		}
		else
		{
			SendClientMessage(playerid, HELP_MSG_COLOR, "No Missions made to show!");
		}
	
		db_free_result(db_result);

		return 1;

}
/*=====================================================

When admin wants to delete an existing mission...

=====================================================*/

CMD:delmis(playerid,params[])
{

		new name[24];
	
		new query[60];
	
		if(!sscanf(params,"s[24]", name))
		{
	
			format(query, sizeof query, "DROP TABLE IF EXISTS '%s' ", name);

			db_query(MissionHandler, query);
	
			format(query, sizeof query, "DELETE FROM `mission_vars` WHERE `name` = '%s' ", name);
	
			db_query(MissionHandler,query);

			CallRemoteFunction("LoadAllMissionPoints","");
	
			SendClientMessage(playerid, HELP_MSG_COLOR, "{FFF000}Deleted Mission, use /showmis to show existing missions!");
	
		}

		return 1;
}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************



/*=================================================

------------------G R O U P S---------------------

Each group has ordered missions in it, 
subsequent mission unlocks when previous mission is completed successfully

----|DB Level Storage Mechanism:

-store group name in every mission field that belongs to that group along with order

-when player completes first mission, keep track of it in another table and use it unlock next missions in that group

----|CMDS:

-MGroupNames: Show list of groups

-MGroupMissions [group name]: show list of missions in a particular group

-MGroupAddMission [group name], [mission name]: Add a mission to a group

-MGroupChangeOrder [group name], [mission name], [order]: change order of a mission inside a group

-MgroupDelMission [group name], [mission name]: delete a mission from a group

SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

=================================================*/

CMD:mghelp(playerid,params[])
{

	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;

}
CMD:MGroupNames(playerid,params[])
{

	/*
		Show all available groups
	*/

	//store each group name fetched
	new EachGroupNameFromDB[50];

	//format each group name and show it...
	new ShowEachGroupFormatted[100];

	SendClientMessage(playerid,GROUP_MSG_COLOR,"********: EXISTING GROUP NAMES!");

	new DBResult: db_result = db_query(MissionHandler, "SELECT DISTINCT `group_name` FROM `mission_vars` WHERE `group_name` IS NOT NULL");

	new index = 0;
	do
	{

		db_get_field_assoc(db_result, "group_name",EachGroupNameFromDB, 50);

		format(ShowEachGroupFormatted,sizeof(ShowEachGroupFormatted),"**: %s\n",EachGroupNameFromDB);

		SendClientMessage(playerid,GROUP_MSG_COLOR,ShowEachGroupFormatted);

		index += 1;				

	}
	while(db_next_row(db_result));
			
	db_free_result(db_result);

	SendClientMessage(playerid,GROUP_MSG_COLOR,"***********************\n");

	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;
	
}


CMD:MGroupMissions(playerid,params[])
{

	//to parse query
	new query[200];

	//To View missions inside a group
	new EachMissionInsideGroupName[50];

	//format each group name and show it...
	new ShowEachMissionFormatted[100];

	new MissionSequence;

	SendClientMessage(playerid,GROUP_MSG_COLOR,"********: EXISTING MISSIONS INSIDE THIS GROUP!");

	format(query,sizeof(query),"SELECT DISTINCT `name`,`grp_msn_sequence` FROM `mission_vars` WHERE `group_name`= '%s' ",params);

	new DBResult: db_result = db_query(MissionHandler, query);

	new index = 0;
	do
	{
		
		MissionSequence = db_get_field_assoc_int(db_result,"grp_msn_sequence");

		db_get_field_assoc(db_result, "name",EachMissionInsideGroupName, 50);

		format(ShowEachMissionFormatted,sizeof(ShowEachMissionFormatted),"** NAME: %s --> ORDER: %d \n",EachMissionInsideGroupName,MissionSequence);

		SendClientMessage(playerid,GROUP_MSG_COLOR,ShowEachMissionFormatted);

		index += 1;				

	}
	while(db_next_row(db_result));
			
	db_free_result(db_result);

	SendClientMessage(playerid,GROUP_MSG_COLOR,"***********************\n");
	
	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;


}


CMD:MGroupAddMission(playerid,params[])
{
	/*
	Two Scenarios:
	-Making a new group and assigning it's first mission using the cmd
	-Already a group exists and adding a mission to it's sequence
	*/
	
	//First, we check if that group exists or not...

	new GroupNameEntered[24];

	new MissionNameEntered[24];

	if(!sscanf(params,"s,s",GroupNameEntered,MissionNameEntered))
	{
		//to parse query
		
		new query[200];

		format(query,sizeof(query),"SELECT MAX(`grp_msn_sequence`) AS MaxSequence FROM `mission_vars` WHERE `group_name`= '%s' ",GroupNameEntered);

		new DBResult: db_result = db_query(MissionHandler, query);

		if(db_num_rows(db_result) == 0)
		{
			//Making a new group and adding this in mission...

			format(query,sizeof(query),"SELECT * FROM `mission_vars` WHERE `name`= '%s' ",MissionNameEntered);

			new DBResult: msn_exists = db_query(MissionHandler, query);
			
			if(db_num_rows(msn_exists) == 0)
			{
				SendClientMessage(playerid,GROUP_MSG_COLOR,"The mission you have entered doesn't exist, please enter proper values!");
			}
			else
			{
				//mission exists, add group name to that mission row in db...

				format(query, sizeof query, " UPDATE `mission_vars` SET `group_name` = '%s',`grp_msn_sequence` = 1 WHERE `name` = '%s' ", GroupNameEntered,MissionNameEntered);
		
				db_free_result(db_query(MissionHandler,query));

			}

		}
		else
		{
			//add this group to that mission with max seq number + 1

			new MaxSqn = db_get_field_assoc_int(db_result, "MaxSequence");

			format(query, sizeof query, " UPDATE `mission_vars` SET `group_name` = '%s',`grp_msn_sequence` = %d + 1 WHERE `name` = '%s' ", GroupNameEntered, MaxSqn,MissionNameEntered);
		
			db_free_result(db_query(MissionHandler,query));

		}

	}
	
	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;
}

CMD:MGroupChangeOrder(playerid,params[])
{

	//-MGroupChangeOrder [group name], [mission name], [order]: change order of a mission inside a group


	/*
	Scenarios:
	Let N_Seq represent new sequence order entered by player for a mission
	Let P_Seq represent existing present order of the mission entered by player
	-After validating group name and mission name and they match the criteria:
		-if N_Seq > P_Seq:
			-if N_Seq > Max Sequence order of that group
				: Invalid
			-if N_Seq < Max Seq order of that group
				:Make -1 for msn_seq for missions between P_Seq and N_Seq 

	*/
	
	new GroupNameEntered[24];

	new MissionNameEntered[24];

	new MsnSeqEntered;

	if(!sscanf(params,"s,s,d",GroupNameEntered,MissionNameEntered,MsnSeqEntered))
	{
		//to parse query
		
		new query[200];

		format(query,sizeof(query),"SELECT `grp_msn_sequence` AS MaxSequence FROM `mission_vars` WHERE `group_name`= '%s' AND `name` = '%s' ",GroupNameEntered,MissionNameEntered);

		new DBResult: db_result = db_query(MissionHandler, query);

		new PresentMsnSeq = db_get_field_assoc_int(db_result, "MaxSequence");

		if(db_num_rows(db_result) == 0 || MsnSeqEntered > PresentMsnSeq) //group name doesnt exist or the entered seq is greater than existing max sequence...
		{

			SendClientMessage(playerid,GROUP_MSG_COLOR,"The group you have entered doesn't exist, Use /MissionGroups for existing group names!");

		}
		else
		{

			//mission also exists, now check p_new and n_new

			if(PresentMsnSeq > MsnSeqEntered)
			{
				/*
					consider 1,2,3,4,5
					Say 3 is N_seq and 5 is P_seq
					5 would be in 3rd position, 3,4 would be shifted right
					new seq would be 1,2,5,3,4
				*/

				format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = `grp_msn_sequence` + 1 WHERE `group_name` = '%s' AND grp_msn_sequence BETWEEN %d AND %d", GroupNameEntered, MsnSeqEntered,PresentMsnSeq-1);
		
				db_free_result(db_query(MissionHandler,query));


				format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = %d WHERE `name` = '%s' AND `group_name` = '%s' ", MsnSeqEntered, MissionNameEntered,GroupNameEntered);
		
				db_free_result(db_query(MissionHandler,query));


			}
			else
			{
				/*
					consider 1,2,3,4,5
					Say 5 is N_seq and 3 is P_seq
					5 would be in 3rd position, 3,4 would be shifted right
					new seq would be 1,2,4,5,3
				*/

				format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = `grp_msn_sequence` -1  WHERE `group_name` = '%s' AND grp_msn_sequence BETWEEN %d AND %d", GroupNameEntered,PresentMsnSeq + 1 ,MsnSeqEntered);
		
				db_free_result(db_query(MissionHandler,query));


				format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = %d WHERE `name` = '%s' AND `group_name` = '%s' ", MsnSeqEntered, MissionNameEntered,GroupNameEntered);
		
				db_free_result(db_query(MissionHandler,query));
			}

		}

	}
	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;
}


CMD:MGroupDelMission(playerid,params[])
{
	//MgroupDelMission [group name], [mission name]: delete a mission from a group

	new GroupNameEntered[24];

	new MissionNameEntered[24];

	if(!sscanf(params,"s,s",GroupNameEntered,MissionNameEntered))
	{
		//to parse query
		
		new query[200];

		format(query,sizeof(query),"SELECT `grp_msn_sequence` AS MaxSequence FROM `mission_vars` WHERE `group_name`= '%s' AND `name` = '%s' ",GroupNameEntered,MissionNameEntered);

		new DBResult: db_result = db_query(MissionHandler, query);

		new PresentMsnSeq = db_get_field_assoc_int(db_result, "MaxSequence");

		if(db_num_rows(db_result) == 0 ) //group name doesnt exist or mission name doesn't exist...
		{

			SendClientMessage(playerid,GROUP_MSG_COLOR,"The group or the mission name you have entered doesn't exist, Use /MissionGroups for existing group names!");
		
		}
		else
		{
			format(query,sizeof(query),"SELECT MAX(`grp_msn_sequence`) AS MaxSequence FROM `mission_vars` WHERE `group_name`= '%s' ",GroupNameEntered);

			new DBResult: max_sqn = db_query(MissionHandler, query);

			new MaxMsnSequence = db_get_field_assoc_int(max_sqn, "MaxSequence");

			format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = `grp_msn_sequence` -1  WHERE `group_name` = '%s' AND grp_msn_sequence BETWEEN %d AND %d", GroupNameEntered,PresentMsnSeq + 1 ,MaxMsnSequence);
		
			db_free_result(db_query(MissionHandler,query));


			format(query, sizeof query, " UPDATE `mission_vars` SET `grp_msn_sequence` = NULL,`group_name` = NULL WHERE `name` = '%s' AND `group_name` = '%s' ", MissionNameEntered,GroupNameEntered);
		
			db_free_result(db_query(MissionHandler,query));

		}

	}

	SendClientMessage(playerid,GROUP_MSG_COLOR,"/MGroupNames , /MGroupMissions, /MGroupAddMission , /MGroupChangeOrder , /MgroupDelMission");

	return 1;

}


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************

ShowRelevantDialog(playerid,dialog_num) //used to show relevant dialog to player
{
	switch(dialog_num)
	{

			case SHOW_DIALOG_MISSION_VARS:
			{	
				ShowPlayerDialog(playerid, SHOW_DIALOG_MISSION_VARS, DIALOG_STYLE_LIST,"Input Mission Vars","Time to complete mission(in seconds) \n Set Weather(0-20) \nSet mission icon marker(0-63)\n Enter way to start mission(0 checkpoint, 1 phone, 2 convo with actor)\nAdd convo lines for mission start(1-5)\n Set start mission actor id(0-311) (set -1 for random skin) \n Create new task \n Delete Last Created Task \n End Mission!", "select","");
			}
			case SHOW_DIALOG_TASK_TYPE:
			{
				ShowPlayerDialog(playerid, SHOW_DIALOG_TASK_TYPE, DIALOG_STYLE_LIST,"Select Task Type!"," GET TO CHECKPOINT(veh doesnt get destroyed useful for races) \n FIND_OBJ \n ENTER_HIDDEN_VEH (without mapicon) \n FIND_HIDDEN_OBJ (without mapicon) \n ENTER_VEH (leading mission should be dest type) \n GET TO FINAL CHECKPOINT(veh gets destroyed once reached) \n TASK_GOTO_ACTOR \n TASK_TALK_TO_ACTOR \n TASK_KILL_ACTOR", "select","");
			}
			case SHOW_DIALOG_MVAR_INPUT:
			{
				ShowPlayerDialog(playerid, SHOW_DIALOG_MVAR_INPUT, DIALOG_STYLE_INPUT, "Information", "Enter value below:", "SET!", "");
			}			
			case SHOW_DIALOG_TASK_VARS:
			{
				ShowPlayerDialog(playerid, SHOW_DIALOG_TASK_VARS, DIALOG_STYLE_LIST,"Edit Task information","Task info msg* \n Task info style(0 - 2)* \n vehid \n Objid (Commonly used:321-372) or Actorid (0-311) (-1 for Random actor skin) \n Mapiconid(0-63) \n Set Actor Dialog \n Reward Wep \n Reward Skin(0-311) \n Reward Cash \n Finish Task", "select","");
			}
			case SHOW_DIALOG_TASK_VARS_INPUT:
			{
				ShowPlayerDialog(playerid, SHOW_DIALOG_TASK_VARS_INPUT, DIALOG_STYLE_INPUT, "Information", "Enter value below:", "SET!", "");
			}
			case SHOW_DIALOG_WEP_LIST:
			{
				new str[884+1];

				format(str, sizeof(str), "%sWEAPON_BRASSKNUCKLE\nWEAPON_GOLFCLUB\nWEAPON_NITESTICK\nWEAPON_KNIFE\nWEAPON_BAT\nWEAPON_SHOVEL\nWEAPON_POOLSTICK\nWE", str);
				format(str, sizeof(str), "%sAPON_KATANA\nWEAPON_CHAINSAW\nWEAPON_DILDO\nWEAPON_DILDO2\nWEAPON_VIBRATOR\nWEAPON_VIBRATOR\nWEAPON_FLOWER\nWEAPON_CANE\nWEAPON_GRENADE\nWEAPON_TEARG", str);
				format(str, sizeof(str), "%sAS\nWEAPON_MOLTOV\nWEAPON_COLT45\nWEAPON_SILENCED\nWEAPON_DEAGLE\nWEAPON_SHOTGUN\nWEAPON_SAWEDOFF\nWEAPON_SHOTGSPA\nWEAPON_UZI\nWEAPON_MP5\nW", str);
				format(str, sizeof(str), "%sEAPON_AK47\nWEAPON_M4\nWEAPON_TEC9\nWEAPON_RIFLE\nWEAPON_SNIPER\nWEAPON_ROCKETLAUNCHER\nWEAPON_HEATSEEKER\nWEAPON_FLAMETHROWER\nWEAPON_MINIGUN\nWEAPO", str);
				format(str, sizeof(str), "%sN_SATCHEL\nWEAPON_BOMB\nWEAPON_SPRAYCAN\nWEAPON_FIREEXTINGUISHER\nWEAPON_CAMERA\nWEAPON_PARACHUTE\n", str);

				ShowPlayerDialog(playerid, SHOW_DIALOG_WEP_LIST, DIALOG_STYLE_LIST, "weapon list", str, "Accept", "Cancel");	
			}
			
	}
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{

	switch(dialogid)
	{
		case SHOW_DIALOG_MISSION_VARS: //main mission dialog 
		{
			switch(listitem)
			{
				case MV_TIMEAMOUNT: //selected timeamount thing, for inputting a value into main mission db
				{
					SelectMissionVar(playerid,MV_TIMEAMOUNT);
				}
				case MV_WEATHER:
				{
					SelectMissionVar(playerid,MV_WEATHER);
				}
				case MV_MAP_ICON:
				{
					SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Mission_MapIcons_Menu);
				}
				case MV_START_TYPE:
				{
					SelectMissionVar(playerid,MV_START_TYPE);
				}
				case MV_START_INFO:
				{
					SendClientMessage(playerid,HELP_MSG_COLOR,"use /dialog [dialog_col(1-5)] [text] to set dialog");
				}
				case MV_START_ACTOR_ID:
				{
					SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Mission_Skin_Menu);
				}
				case MV_CREATE_TASK:
				{
					ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_TYPE);
				}
				case MV_DELETE_LAST_CREATED_TASK:
				{
					new query[80];

					format(query, sizeof query,"DELETE FROM `%s` WHERE `taskid` = %d", mission_vars[playerid][MNAME],mission_vars[playerid][TASK_NUMBER]);

					db_query(MissionHandler, query);

					format(query, sizeof query, "UPDATE `mission_vars` SET numtasks = numtasks - 1 WHERE `name` = '%s' ",  mission_vars[playerid][MNAME]);

					db_query(MissionHandler, query);

					format(query,sizeof query, "Last task number: %d deleted from database", mission_vars[playerid][TASK_NUMBER]);

					SendClientMessage(playerid, HELP_MSG_COLOR, query);

					mission_vars[playerid][TASK_NUMBER]--;

					format(query,sizeof query, "Total no.of tasks now: %d", mission_vars[playerid][TASK_NUMBER]);

					SendClientMessage(playerid, HELP_MSG_COLOR, query);


					ShowRelevantDialog(playerid,SHOW_DIALOG_MISSION_VARS);

				}
				case MV_FINISH:
				{
					TextDrawHideForPlayer(playerid, TextMName);

					TextDrawHideForPlayer(playerid,TextTInfo);

					SendClientMessage(playerid,HELP_MSG_COLOR,"Use /create (string) to create another mission");

					OnPlayerFinishMakingMission(playerid);

					CallRemoteFunction("LoadJustAddedMissionPoint","s",mission_vars[playerid][MNAME]);// adds the newly made mission into the world...

					ResetVars(playerid);
				}
			}
		}
		case SHOW_DIALOG_TASK_TYPE:
		{

			CreateTask(playerid,listitem);

		}
		case SHOW_DIALOG_MVAR_INPUT: //for taking inputs in missionvars
		{
			SetValIntoMissionDB(playerid,inputtext);
		}
		
		case SHOW_DIALOG_TASK_VARS:
		{
			mission_vars[playerid][ChosenListItem] = listitem;

			switch(mission_vars[playerid][ChosenListItem])
			{
				case taskinfo:
				{				
					SendClientMessage(0, 0xFFF000FF, "The message to show when player starts the task!");
				}
				case infostyle:
				{
					SendClientMessage(0, 0xFFF000FF, "0- in chat \n 1- bottom in singleplayer conversation style \n 2- right side in a black semi transparent box ");
				}
				case objid:
				{				
					SendClientMessage(0, 0xFFF000FF, "The model id of actor or pickup you want to set for task!");
				} 
				case mapobjid:
				{					
					SendClientMessage(0, 0xFFF000FF, "The radar mapicon id to set for the entity!");
				}
			}

			if (listitem == finishTask)
			{

				TextDrawHideForPlayer(playerid, TextTInfo);

				ShowRelevantDialog(playerid,SHOW_DIALOG_MISSION_VARS);
				
			}
			else if(listitem == rewardwep)
			{
				ShowRelevantDialog(playerid,SHOW_DIALOG_WEP_LIST);
			}
			else if(listitem == setactordialog)
			{
				SendClientMessage(playerid,HELP_MSG_COLOR,"Set actor dialog through /actdialog [count] [string]");
			}
			else if(listitem == vehid)
			{
				SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Vehicle_Menu);
			}
			else if(listitem == mapobjid)
			{
				SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Task_MapIcons_Menu);
			}
			else if(listitem == objid && (mission_vars[playerid][TASK_TYPE] == TASK_FIND_OBJ || mission_vars[playerid][TASK_TYPE] == TASK_FIND_HIDDEN_OBJ) )
			{
				SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Pickups_Menu);
			}
			else if(listitem == objid && (mission_vars[playerid][TASK_TYPE] == TASK_GOTO_ACTOR || mission_vars[playerid][TASK_TYPE] == TASK_GOTO_ACTOR || mission_vars[playerid][TASK_TYPE] == TASK_TALK_TO_ACTOR) )
			{
				SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Task_Skin_Menu);
			}
			else if(listitem == rewardskin)
			{
				SetTimerEx("WaitOneSecToShowMenu", Timer_Wait_To_Show_Menu_Time, false, "ii", playerid,Timer_Task_Reward_Skin_Menu);
			}
			else
			{
				ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS_INPUT);
			}
		}
		case SHOW_DIALOG_TASK_VARS_INPUT:
		{
			
			SetValIntoTaskRow(playerid,inputtext);
			
		}
		case SHOW_DIALOG_WEP_LIST:
		{
			new query[300];

			format(query, sizeof query, " UPDATE `%s` SET `rewardwep` = %d+1 WHERE `taskid` = %d ", mission_vars[playerid][MNAME], listitem,mission_vars[playerid][TASK_NUMBER]);
			db_free_result(db_query(MissionHandler,query));
			SendClientMessage(playerid,HELP_MSG_COLOR,"wep set!");

			ShowRelevantDialog(0,SHOW_DIALOG_TASK_VARS);
		}

	}


	return 0;
}


//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************



//responses for those menus
MSelectResponse:Vehicle_menu(playerid, MSelectType:response, itemid, modelid)
{
	if(response == MSelect_Item)
	{
		new query[300];

		format(query, sizeof query, " UPDATE `%s` SET `vehid` = %d WHERE `taskid` = %d ", mission_vars[playerid][MNAME], modelid,mission_vars[playerid][TASK_NUMBER]);
		
		db_free_result(db_query(MissionHandler,query));
		
		SendClientMessage(playerid,HELP_MSG_COLOR,"vehicle set!");

		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
			
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Vehicle_menu);
	}
	
	return 1;
}

MSelectResponse:Pickups_Menu(playerid, MSelectType:response, itemid, modelid)
{

	//new msg[60];
	//format(msg, sizeof(msg),"itemid: %d , modelid:",itemid,modelid);
	//SendClientMessage(playerid,-1,msg);
	if(response == MSelect_Item)
	{
		new query[300];

		format(query, sizeof query, " UPDATE `%s` SET `objid` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], modelid,mission_vars[playerid][TASK_NUMBER]);
		
		db_free_result(db_query(MissionHandler,query));

		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
		
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Pickups_Menu);
	}
	return 1;
}


MSelectResponse:Mission_Skin_Menu(playerid, MSelectType:response, itemid, modelid)
{
	if(response == MSelect_Item)
	{
		new query[100];

		format(query, sizeof query, "UPDATE `mission_vars` SET `actorid` = %d WHERE name = '%s' ", modelid, mission_vars[playerid][MNAME]);

		db_free_result(db_query(MissionHandler,query));

		MSelect_Close(playerid);
		
		ShowRelevantDialog(playerid,SHOW_DIALOG_MISSION_VARS);
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Mission_Skin_Menu);
	}
	return 1;
}

MSelectResponse:Task_Skin_Menu(playerid, MSelectType:response, itemid, modelid)
{
	if(response == MSelect_Item)
	{
		new query[300];

		format(query, sizeof query, " UPDATE `%s` SET `objid` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], itemid,mission_vars[playerid][TASK_NUMBER]);
		
		db_free_result(db_query(MissionHandler,query));

		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
		
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Task_Skin_Menu);
	}
	return 1;
}
MSelectResponse:Task_Reward_Skin_Menu(playerid, MSelectType:response, itemid, modelid)
{
	if(response == MSelect_Item)
	{
		new query[300];

		format(query, sizeof query, " UPDATE `%s` SET `rewardskin` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], itemid,mission_vars[playerid][TASK_NUMBER]);

		db_free_result(db_query(MissionHandler,query));

		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);
		
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Task_Reward_Skin_Menu);
	}
	return 1;
}


MSelectResponse:Mission_MapIcons_Menu(playerid, MSelectType:response, itemid, modelid)
{
	
	if(response == MSelect_Item)
	{
		new query[100];

		format(query, sizeof query, "UPDATE `mission_vars` SET `mapicon` = %d WHERE name = '%s' ", itemid + 2, mission_vars[playerid][MNAME]);

		db_free_result(db_query(MissionHandler,query));

		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_MISSION_VARS);		
	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Mission_MapIcons_Menu);
	}

	return 1;
}

MSelectResponse:Task_MapIcons_Menu(playerid, MSelectType:response, itemid, modelid)
{
	
	if(response == MSelect_Item)
	{
		new query[300];

		format(query, sizeof query, " UPDATE `%s` SET `mapobjid` = '%d' WHERE `taskid` = %d", mission_vars[playerid][MNAME], itemid+2,mission_vars[playerid][TASK_NUMBER]);
		db_free_result(db_query(MissionHandler,query));
		
		MSelect_Close(playerid);

		ShowRelevantDialog(playerid,SHOW_DIALOG_TASK_VARS);

	}
	else if (response == MSelect_Cancel)
	{
		MSelect_Show(playerid, MSelect:Task_MapIcons_Menu);
	}

	return 1;
}



//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************


/*=====================================================

below callbacks are available for handling player interactions with missions...

=====================================================*/

//==========================================================================

//for admin making missions callbacks
forward OnPlayerEnterMissionMakingMode(playerid);

public OnPlayerEnterMissionMakingMode(playerid)
{
		SendClientMessage(playerid,HELP_MSG_COLOR,"You have decided to enter into missions making mode!");
}

forward OnPlayerExitMissionMakingMode(playerid); 

public OnPlayerExitMissionMakingMode(playerid)
{
		SendClientMessage(playerid,HELP_MSG_COLOR,"You have decided to exit missions maikng mode!");
}

forward OnPlayerStartCreatingMission(playerid);

public OnPlayerStartCreatingMission(playerid)
{
		SendClientMessage(playerid,HELP_MSG_COLOR,"You are creating a mission right now!");
}

forward OnPlayerFinishMakingMission(playerid); 

public OnPlayerFinishMakingMission(playerid)
{
		SendClientMessage(playerid,HELP_MSG_COLOR,"You have finished making a mision now!");
}

//==========================================================================

//for player playing missions callbacks
forward OnMissionCompletion(playerid,mname[],status,timeleft); //status -> -1 time ran out, 0 failed(disconnected or died during mission), 1 success

public OnMissionCompletion(playerid,mname[],status,timeleft)
{
	
		SendClientMessage(playerid,HELP_MSG_COLOR,"You took part in the mission!");
}

forward OnMissionStart(playerid,mname[]);

public OnMissionStart(playerid,mname[])
{

	new query[70];
	format(query, sizeof query, "You started the mission: %s", mname);
	SendClientMessage(playerid, HELP_MSG_COLOR, query);

}

forward OnTaskStart(playerid,mname[],task_type);

public OnTaskStart(playerid,mname[],task_type)
{

	SendClientMessage(playerid, HELP_MSG_COLOR, "Task started succesfully!");

}

forward OnTaskFinish(playerid,mname[],task_type);

public OnTaskFinish(playerid,mname[],task_type)
{

	SendClientMessage(playerid, HELP_MSG_COLOR, "Task finished succesfully!");

}

public OnPlayerCommandReceived(playerid,cmdtext[])
{
    if(mission_vars[playerid][HAS_ACCESS_TO_EDIT_MISSIONS] == 0)
	{
        SendClientMessage(playerid, -1, "You must have access to mission making feature!");
        return 0;
        
    }
	return 1;
}



//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************



/*=====================================================

For testing purposes...

=====================================================*/

/*//for testing purposes...
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	SetPlayerPos(playerid, Float:fX, Float:fY, Float:fZ + 3.0);
}


CMD:bike(playerid,params[])
{
	new Float:x,Float:y,Float:z;
	GetPlayerPos(playerid,x,y,z);

	new veh = CreateVehicle(461, Float:x, Float:y, Float:z + 10.0, 0.0, 0,0, 0);

	PutPlayerInVehicle(playerid, veh, 0);

	return 1;
}
*/
//CallRemoteFunction("AllowPlayerForMission","ii", playerid,bool:check);

//CallRemoteFunction("StartMissionForPlayer","s",mission_name);




/*public OnPlayerExitVehicle(playerid, vehicleid)
{
	DestroyVehicle(vehicleid);
}*/




