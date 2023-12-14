
/*Do Your Own (M)ission 
..............(M)ultiPlayer!
Create curated custom missions for your server*/


#include <a_samp>

#include <streamer>

#define MISSION_SEND_PLAYER_MSG_COLOR	0x00FF0000

#define START_MISSION_DIALOG_BOX	9

/////////////////////////////////////////////////////////////////////////////////////////////////

#define TASK_INFO_LEN		100

#define MAX_MISSIONS		100

#define TASK_ACTOR_SET_HEALTH	100.0

//==========================================================================================

#define MISSION_START_OBJ_ID	19902

#define MISSION_START_PICKUP_ID	1239

#define MISSION_START_TEXT_COLOR 		0x00FF00FF

#define MISSION_START_CHECKPOINT	0

#define MISSION_START_TALK_PHONE 	1

#define MISSION_START_TALK_NPC		2

#define MISSION_START_MAX_DIALOGS	5

#define MISSION_START_DIALOG_LEN		200

#define MISSION_START_DIALOG_TIME_LEN	2000

//==========================================================================================

#define ARRIVE_DEST			0

#define FIND_OBJ 			1

#define ENTER_HIDDEN_VEH 	2	

#define FIND_HIDDEN_OBJ		3

#define ENTER_VEH 			4

#define TAKE_VEH_TO_DEST	5

#define TASK_GOTO_ACTOR		6

#define TASK_TALK_TO_ACTOR	7

#define TASK_KILL_ACTOR		8

//==========================================================================================

#define REWARD_WEP			1

#define REWARD_CHANGE_SKIN  2

#define REWARD_CASH			3

//==========================================================================================

#define TASK_TEXT_CHAT		0

#define TASK_TEXT_TEXTDRAW  1

#define TASK_TEXT_BLACKBOX 	2

//==========================================================================================

new PlayerText: Textdraw1[MAX_PLAYERS];

new PlayerText: Textdraw2[MAX_PLAYERS];

new PlayerText: TimeTextdraw[MAX_PLAYERS];

new PlayerText:	TextdrawDialog[MAX_PLAYERS];

new PlayerText:	TextdrawActorDialog[MAX_PLAYERS];

//==========================================================================================

static DB:MissionHandler;

//==========================================================================================

/**==========================================================================================
 * The enums hold mission and task info for each player...
 * when player starts a mission, the values gets loaded from the db, and are used as flag checks in each event
 * to consider the next step of the mission 
 * When the mission is done, the vars are set to 0
==========================================================================================*/

enum MISSION_VARS{ //used to hold mission information for the player to keep count of mission, no. of tasks done and to be completed
	
	bool: MISSION_STATUS = false, //to check if player is currently on mission or not...
	NUM_TASKS, //var to hold no.of tasks mission player is doing has...
	TASK_TYPE, // resembles which type of task player is doing... 
	ON_TASK_COUNT, //shows on which task number player is currently on...
	bool: IS_TIMER,
	TIME_AMOUNT,
	MISSION_TIMER_VAR,
	bool: IS_WEATHER_DIFFERENT,
	WEATHER_ID,
	MISSION_NAME[24] //mission name 
	
}

new MissionInfo[MAX_PLAYERS][MISSION_VARS];

//vars to hold task info in each cycle within the mission
enum TASKS_INFO{

	TEXT_STYLE, //how to present the style of task info
	Float: POS_X,//map icon location
	Float: POS_Y,
	Float: POS_Z,
	Float: ROT,//in case need to interact with actor, get actor rot
	OBJ_ID, //to load Checkpoints
	PICKUP_ID,//to load task pickups
	PICKUP_ID_THRU_VEH,//to load task pickups which can be picked up by vehicles
	MAP_OBJ_ID,//to show map icon for respective entity on radar
	ACTOR, //to load actor for interaction with player
	STREAMER_TAG_3D_TEXT_LABEL: ACT_SHOW_HEALTH, //storing actor health
	DIALOG_TIMER, //interaction with actor timer
	VEH_ID, //to load task veh
	ATTACH_OBJ, //to load yellow pointy thing to vehicles in case they are created
	GIVE_REWARD_WEP_ID,  //wep id as reward (ammo defualt 500)
	GIVE_REWARD_CASH, //amount of cash to give on task completion
	GIVE_REWARD_SKIN, //skin to change player in case the mission requries so
	TASK_INFO[TASK_INFO_LEN] //to be shown in beginning of task to guide player what to do
	
}

new TaskInfo[MAX_PLAYERS][TASKS_INFO];

new TaskActorDialog[MAX_PLAYERS][MISSION_START_DIALOG_LEN+1]; //for task type interacting with actor



//individual mission info not related to specific player
enum MISSION_START_INFO{

	MISSION_ID,
	START_TYPE,
	START_ACTOR_ID,
	MAP_ICON_ID,
	ENTER_OBJ,
	Float: POS_X,
	Float: POS_Y,
	Float: POS_Z,
	Float: ACTROT,
	STREAMER_TAG_3D_TEXT_LABEL: TEXT_LABEL,
	MISSION_NAME[24]
}

new MissionStartInfo[MAX_MISSIONS][MISSION_START_INFO];

new MissionStartDialog[MAX_MISSIONS][MISSION_START_DIALOG_LEN+1]; //dialog to show player when mission activated

new MissionStartDialogTimer[MAX_PLAYERS]; //timer for the dialog above (not enumed in missioninfo cus it already has a actor dialog timer so less confusion)

new PlayerChoseMission[MAX_PLAYERS]; //to keep track what mission player interacted with when SHOW_DIALOG is activated

new bool: AllowGlobalMission[MAX_PLAYERS] = {true, ...} ; //to allow players or not to access missions by server

//---------------------------------------------------------------------------------------------------------------------------------

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
///**********************************************************************************************************************************************


/*=====================================================


Functions to load all missions from db...

=====================================================*/
forward ResetMissionValues(playerid);
public ResetMissionValues(playerid) //to reset everything after a mission is completed or failed to complete
{

	MissionInfo[playerid][MISSION_STATUS] = false;
	MissionInfo[playerid][NUM_TASKS] = 0;
	MissionInfo[playerid][TASK_TYPE] = 0;
	MissionInfo[playerid][ON_TASK_COUNT] = 0;
	MissionInfo[playerid][IS_TIMER] = false;
	MissionInfo[playerid][TIME_AMOUNT] = 0;
	MissionInfo[playerid][IS_WEATHER_DIFFERENT] = false;
	MissionInfo[playerid][WEATHER_ID] = 0;
	MissionInfo[playerid][MISSION_TIMER_VAR] = 0;

	
	TaskInfo[playerid][TEXT_STYLE] = 0;
	TaskInfo[playerid][POS_X] = 0.0;
	TaskInfo[playerid][POS_Y] = 0.0;
	TaskInfo[playerid][POS_Z] = 0.0;
	TaskInfo[playerid][MAP_OBJ_ID] = 0;
	TaskInfo[playerid][PICKUP_ID] = 0;
	TaskInfo[playerid][PICKUP_ID_THRU_VEH] = 0;
	TaskInfo[playerid][ACTOR] = 0;
	TaskInfo[playerid][DIALOG_TIMER] = 0;
	TaskInfo[playerid][OBJ_ID] = 0;
	TaskInfo[playerid][VEH_ID] = 0;
	TaskInfo[playerid][ATTACH_OBJ] = 0;
	TaskInfo[playerid][GIVE_REWARD_WEP_ID] = 0;
	TaskInfo[playerid][GIVE_REWARD_CASH] = 0;
	TaskInfo[playerid][GIVE_REWARD_SKIN] = 0;
	
	PlayerChoseMission[playerid] = 0;

}


//finds number of missions in db rn...
FindMaxFilledMissionIndex()
{
	new index;
	for(new i=0; i< sizeof(MissionStartInfo);i++)
	{
		if(MissionStartInfo[i][MISSION_ID] == '\0')
		{
			index = i;
			break;
		}
	}
	return index;
}


RemoveMissionStartInfoObjects()
{
	for(new i=0; i< sizeof(MissionStartInfo);i++)
	{
		if(MissionStartInfo[i][MISSION_ID] != '\0')
		{
			if( IsValidDynamicArea(MissionStartInfo[i][MISSION_ID]) )
			{
				DestroyDynamicArea(MissionStartInfo[i][MISSION_ID]);
			}
			if( IsValidDynamicMapIcon(MissionStartInfo[i][MAP_ICON_ID]) )
			{
				DestroyDynamicMapIcon(MissionStartInfo[i][MAP_ICON_ID]);
			}
			if( IsValidDynamic3DTextLabel(MissionStartInfo[i][TEXT_LABEL]) )
			{
				DestroyDynamic3DTextLabel(MissionStartInfo[i][TEXT_LABEL]);
			}
			if( IsValidDynamicActor(MissionStartInfo[i][START_ACTOR_ID]))
			{
				DestroyDynamicActor(MissionStartInfo[i][START_ACTOR_ID]);
			}

			if( IsValidDynamicPickup(MissionStartInfo[i][ENTER_OBJ]))
			{
				DestroyDynamicPickup(MissionStartInfo[i][ENTER_OBJ]);
			}
			else if ( IsValidDynamicObject(MissionStartInfo[i][ENTER_OBJ]))
			{
				DestroyDynamicObject(MissionStartInfo[i][ENTER_OBJ]);
			}

		}
	}
}



//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************


forward LoadJustAddedMissionPoint(NewlyAddedMissionName[]);
public LoadJustAddedMissionPoint(NewlyAddedMissionName[]) //on start of server, mission points gets activated for players to see and access...
{


	new query[400];

	format(query, sizeof query, "SELECT `name`,`starttype`,`mapicon`, `actorid`,`start_x`,`start_y`,`start_z`,`actrot` FROM `mission_vars` where `name` = '%s' ", NewlyAddedMissionName);
	
	new DBResult: db_result = db_query(MissionHandler, query);


	new Next_Mission_Index = FindMaxFilledMissionIndex();

	MissionStartInfo[Next_Mission_Index][POS_X] = db_get_field_assoc_float(db_result, "start_x");
	
	MissionStartInfo[Next_Mission_Index][POS_Y] = db_get_field_assoc_float(db_result, "start_y");

	MissionStartInfo[Next_Mission_Index][POS_Z] = db_get_field_assoc_float(db_result, "start_z");

	MissionStartInfo[Next_Mission_Index][START_TYPE] = db_get_field_assoc_int(db_result,"starttype");

	MissionStartInfo[Next_Mission_Index][MAP_ICON_ID] = db_get_field_assoc_int(db_result,"mapicon");

	MissionStartInfo[Next_Mission_Index][START_ACTOR_ID] = db_get_field_assoc_int(db_result,"actorid");

	MissionStartInfo[Next_Mission_Index][ACTROT] = db_get_field_assoc_float(db_result, "actrot");


	db_get_field_assoc(db_result, "name", MissionStartInfo[Next_Mission_Index][MISSION_NAME], 24);

	printf("Just added the mission to live: %s", MissionStartInfo[Next_Mission_Index][MISSION_NAME]);

	MissionStartInfo[Next_Mission_Index][MISSION_ID] = CreateDynamicCylinder(MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z]-5.0,MissionStartInfo[Next_Mission_Index][POS_Z]+5.0, 1.0 );

	new mlabel[35];

	format(mlabel, sizeof mlabel,"MISSION:\n\"%s\"   ", MissionStartInfo[Next_Mission_Index][MISSION_NAME]);

	MissionStartInfo[Next_Mission_Index][TEXT_LABEL] = CreateDynamic3DTextLabel(mlabel, MISSION_START_TEXT_COLOR,MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z],30.0);
	
	MissionStartInfo[Next_Mission_Index][MAP_ICON_ID] = CreateDynamicMapIcon(MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z], MissionStartInfo[Next_Mission_Index][MAP_ICON_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL);

	switch(MissionStartInfo[Next_Mission_Index][START_TYPE]) 
	{
		case MISSION_START_CHECKPOINT:
		{
		MissionStartInfo[Next_Mission_Index][ENTER_OBJ] = CreateDynamicObject(MISSION_START_OBJ_ID, MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z],0.0,0.0,0.0);

		}
		case MISSION_START_TALK_PHONE:
		{
			MissionStartInfo[Next_Mission_Index][ENTER_OBJ] = CreateDynamicPickup(MISSION_START_PICKUP_ID, 8, MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z]);
			
		}
		case MISSION_START_TALK_NPC:
		{

			MissionStartInfo[Next_Mission_Index][ENTER_OBJ] = CreateDynamicObject(MISSION_START_OBJ_ID, MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z] + 1.0 ,0.0,0.0,0.0);

			if(MissionStartInfo[Next_Mission_Index][START_ACTOR_ID] == -1)
			{
				MissionStartInfo[Next_Mission_Index][START_ACTOR_ID] = CreateDynamicActor(random(311), MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z], MissionStartInfo[Next_Mission_Index][ACTROT]); 	
			}
			else
			{
				MissionStartInfo[Next_Mission_Index][START_ACTOR_ID] = CreateDynamicActor(MissionStartInfo[Next_Mission_Index][START_ACTOR_ID], MissionStartInfo[Next_Mission_Index][POS_X], MissionStartInfo[Next_Mission_Index][POS_Y],MissionStartInfo[Next_Mission_Index][POS_Z], MissionStartInfo[Next_Mission_Index][ACTROT]); 	
			}
		}
	}


}

forward LoadAllMissionPoints();
public LoadAllMissionPoints() //on start of server, mission points gets activated for players to see and access...
{

	RemoveMissionStartInfoObjects(); //when a mission is deleted, remove all attachments between vars and db values and reload all missions spawn points....

	new DBResult: db_result = db_query(MissionHandler, "SELECT `name`,`starttype`,`mapicon`, `actorid`,`start_x`,`start_y`,`start_z`,`actrot` FROM `mission_vars`");

	new index = 0;
	do
	{
		MissionStartInfo[index][POS_X] = db_get_field_assoc_float(db_result, "start_x");
		
		MissionStartInfo[index][POS_Y] = db_get_field_assoc_float(db_result, "start_y");

		MissionStartInfo[index][POS_Z] = db_get_field_assoc_float(db_result, "start_z");

		MissionStartInfo[index][START_TYPE] = db_get_field_assoc_int(db_result,"starttype");

		MissionStartInfo[index][MAP_ICON_ID] = db_get_field_assoc_int(db_result,"mapicon");

		MissionStartInfo[index][START_ACTOR_ID] = db_get_field_assoc_int(db_result,"actorid");
 
		MissionStartInfo[index][ACTROT] = db_get_field_assoc_float(db_result, "actrot");


		db_get_field_assoc(db_result, "name", MissionStartInfo[index][MISSION_NAME], 24);

		printf("Loaded Mission from DB: %s \n", MissionStartInfo[index][MISSION_NAME]);

		MissionStartInfo[index][MISSION_ID] = CreateDynamicCylinder(MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z]-5.0,MissionStartInfo[index][POS_Z]+5.0, 1.0 );

		new mlabel[35];

		format(mlabel, sizeof mlabel,"MISSION:\n\"%s\"   ", MissionStartInfo[index][MISSION_NAME]);

		MissionStartInfo[index][TEXT_LABEL] = CreateDynamic3DTextLabel(mlabel, MISSION_START_TEXT_COLOR,MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z],30.0);
	
		MissionStartInfo[index][MAP_ICON_ID] = CreateDynamicMapIcon(MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z], MissionStartInfo[index][MAP_ICON_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL);

		switch(MissionStartInfo[index][START_TYPE]) 
		{
			case MISSION_START_CHECKPOINT:
			{
				MissionStartInfo[index][ENTER_OBJ] = CreateDynamicObject(MISSION_START_OBJ_ID, MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z],0.0,0.0,0.0);

			}
			case MISSION_START_TALK_PHONE:
			{

				MissionStartInfo[index][ENTER_OBJ] = CreateDynamicPickup(MISSION_START_PICKUP_ID, 8, MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z]);
			
			}
			case MISSION_START_TALK_NPC:
			{

				MissionStartInfo[index][ENTER_OBJ] = CreateDynamicObject(MISSION_START_OBJ_ID, MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z] + 1.0 ,0.0,0.0,0.0);

				if(MissionStartInfo[index][START_ACTOR_ID] == -1)
				{
					MissionStartInfo[index][START_ACTOR_ID] = CreateDynamicActor(random(311), MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z], MissionStartInfo[index][ACTROT]); 	
				}
				else
				{
					MissionStartInfo[index][START_ACTOR_ID] = CreateDynamicActor(MissionStartInfo[index][START_ACTOR_ID], MissionStartInfo[index][POS_X], MissionStartInfo[index][POS_Y],MissionStartInfo[index][POS_Z], MissionStartInfo[index][ACTROT]); 	
				}
			}
		}
		index += 1;				
	}
	while(db_next_row(db_result) && index < MAX_MISSIONS);

	db_free_result(db_result);

}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************

/*-------------------------------------------------------------------------------------------------------------------------

Functions to load dialogs from db and show them to player in a sequential manner...

--------------------------------------------------------------------------------------------------------------------------*/
forward PresentDialog(playerid,index,count ); //to show initial mission dialog

public PresentDialog(playerid,index,count )
{
	new text[9];

	new query[100];

	format(text, sizeof text,"dialog_%d", count);

	format(query, sizeof query," SELECT `%s` FROM `mission_vars` WHERE `name` = '%s' ",text, MissionStartInfo[index][MISSION_NAME]);

	new DBResult:db_result = db_query(MissionHandler, query);

	db_get_field_assoc(db_result,text,query, 100);	

	if(query[0] != EOS && count <= MISSION_START_MAX_DIALOGS )
	{

		strdel(MissionStartDialog[index], 0, strlen(MissionStartDialog[index]) );

		strins(MissionStartDialog[index],query, 0, 100);

		PlayerTextDrawSetString(playerid,TextdrawDialog[playerid], MissionStartDialog[index]);

		PlayerTextDrawShow(playerid, TextdrawDialog[playerid]);

		db_free_result(db_result);

		KillTimer(MissionStartDialogTimer[playerid]);

		MissionStartDialogTimer[playerid] = SetTimerEx("PresentDialog", MISSION_START_DIALOG_TIME_LEN, 1,"iii",playerid,index,count +1);
	}
	else
	{
		switch(MissionStartInfo[index][START_TYPE])
		{
			case MISSION_START_TALK_PHONE:
			{
				PlayerTextDrawHide(playerid,TextdrawDialog[playerid]);
				KillTimer(MissionStartDialogTimer[playerid]);
				SetPlayerSpecialAction(playerid, 13); 
			}
			case MISSION_START_TALK_NPC:
			{
				PlayerTextDrawHide(playerid,TextdrawDialog[playerid]);
				KillTimer(MissionStartDialogTimer[playerid]);
				ClearAnimations(playerid);
				ClearDynamicActorAnimations(MissionStartInfo[index][START_ACTOR_ID]);
			}
		}

		//player has fininshed conversing to npc about mission, now it starts...
		LoadMissionOnStart(playerid,MissionStartInfo[index][MISSION_NAME]);
	}

}

forward PresentActorDialog(playerid,count); 

public PresentActorDialog(playerid,count) //to show task type actor dialog
{

	new text[9];

	new query[100];

	format(text, sizeof text,"dialog_%d", count);

	format(query, sizeof query," SELECT `%s` FROM '%s' WHERE `taskid` = %d ",text, MissionInfo[playerid][MISSION_NAME], MissionInfo[playerid][ON_TASK_COUNT]);

	new DBResult:db_result = db_query(MissionHandler, query);

	db_get_field_assoc(db_result,text,query, 100);	


	if(query[0] != EOS && count <= MISSION_START_MAX_DIALOGS)
	{	
		strdel(TaskActorDialog[playerid], 0, strlen(TaskActorDialog[playerid]) );

		strins(TaskActorDialog[playerid],query, 0, 100);

		PlayerTextDrawSetString(playerid,TextdrawActorDialog[playerid], TaskActorDialog[playerid]);

		PlayerTextDrawShow(playerid, TextdrawActorDialog[playerid]);

		db_free_result(db_result);

		KillTimer(TaskInfo[playerid][DIALOG_TIMER]);

		TaskInfo[playerid][DIALOG_TIMER] = SetTimerEx("PresentActorDialog", MISSION_START_DIALOG_TIME_LEN, 1,"ii",playerid,count +1);
	}
	else
	{
		PlayerTextDrawHide(playerid,TextdrawActorDialog[playerid]);
		KillTimer(TaskInfo[playerid][DIALOG_TIMER]);
		ClearAnimations(playerid);
		ClearActorAnimations(TaskInfo[playerid][OBJ_ID]);
		DestroyDynamicActor(TaskInfo[playerid][ACTOR]);
		DestroyDynamicCP(TaskInfo[playerid][OBJ_ID]);
		DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);
		GiveTaskReward(playerid);

	}
}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************


/**********************************HELPER FUNCTIONS TO LOAD DB DATA INTO PLAYER VARS********************************/
 

//-------------------------------------------------------------------------


forward ShowPlayerTaskInfo(playerid);

public ShowPlayerTaskInfo(playerid) //to show taskinfo textdraw
{
	new query[100];

	GameTextForPlayer(playerid,TaskInfo[playerid][TASK_INFO] , 3000, 6);

	switch(TaskInfo[playerid][TEXT_STYLE])
	{
		case TASK_TEXT_CHAT:
		{
			format(query,sizeof query, "%s",TaskInfo[playerid][TASK_INFO]);
			SendClientMessage(playerid, MISSION_SEND_PLAYER_MSG_COLOR, query);

		}
		case TASK_TEXT_TEXTDRAW:
		{
			
			PlayerTextDrawShow(playerid, Textdraw1[playerid] );
			format(query,sizeof query, "%s",TaskInfo[playerid][TASK_INFO]);
		}
		case TASK_TEXT_BLACKBOX:
		{
			PlayerTextDrawShow(playerid, Textdraw2[playerid] );

		}
	}
}


forward MissionTimerCheck(playerid);

public MissionTimerCheck(playerid)
{
	new query[25];
	MissionInfo[playerid][TIME_AMOUNT]  -= 1;
	format(query, sizeof query,"~r~Time Left:~w~ %d", MissionInfo[playerid][TIME_AMOUNT]);


	if (MissionInfo[playerid][TIME_AMOUNT] > 0)
	{
		PlayerTextDrawSetString(playerid,TimeTextdraw[playerid], query);

	}
	else //time has run out, delete player task vars (objs) and end the mission with status = -1 (failed)
	{

		ResetEverythingForPlayer(playerid,MissionInfo[playerid][MISSION_NAME],-1,0);

	}  
}


forward ApplyMissionProperties(playerid);

public ApplyMissionProperties(playerid)
{
	if(MissionInfo[playerid][IS_WEATHER_DIFFERENT] == true)
	{
		SetPlayerWeather(playerid, MissionInfo[playerid][WEATHER_ID]);
	}
	if(MissionInfo[playerid][IS_TIMER] == true)
	{
		new query[25];
		format(query,sizeof query,"~r~Time Left:~w~ %d",MissionInfo[playerid][TIME_AMOUNT]);

		PlayerTextDrawSetString(playerid,TimeTextdraw[playerid], query);
		
		PlayerTextDrawShow(playerid, TimeTextdraw[playerid]);

		MissionInfo[playerid][MISSION_TIMER_VAR] = SetTimerEx("MissionTimerCheck", 1000, true, "i", playerid);

	} 

}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************


/*=========================================MAIN FUNCTIONS WHICH GET EXECUTED IN A CYCLE FOR TASKS===================================================


=====================================================
 --when a mission starts, each task gets loaded into player vars and is executed in a cycle,
 --which repeats itself until the tasks are done or player has died or disconnected 


LoadMissionOnStart ----> LoadMInfoToPlayer ----> ApplyMissionProperties ---->  LoadPlayerTask ----> 

LoadTInfoToPlayer ----> InitialiseTask ---> CheckActionCompletion(this happens randomly which is checked in callbacks) ---->

EndTask ---> GiveTaskReward ----> LoadPlayerTask

=====================================================*/

forward LoadMissionOnStart(playerid, mission_name[]);

public LoadMissionOnStart(playerid,mission_name[]) //called to start the mission for the player
{
	ResetMissionValues(playerid);
	//check if mission exists based on name
	//load sql vars into MissionInfo
	//LoadPlayerTask(playerid,mission_id)
	strdel(MissionInfo[playerid][MISSION_NAME], 0, strlen(MissionInfo[playerid][MISSION_NAME]) );

	strins(MissionInfo[playerid][MISSION_NAME], mission_name,0);

	CallRemoteFunction("OnMissionStart", "is", playerid,MissionInfo[playerid][MISSION_NAME]);

	LoadMInfoToPlayer(playerid);

	MissionInfo[playerid][MISSION_STATUS] = true;

	

}

forward LoadMInfoToPlayer(playerid);

public LoadMInfoToPlayer(playerid) //load db stuff into player vars
{
	new query[100];//for getting numtasks

	format(query, sizeof query, "SELECT `numtasks`,`timeamount`,`weather` FROM `mission_vars` WHERE `name` = '%s' ",MissionInfo[playerid][MISSION_NAME]);
	new DBResult:db_result = db_query(MissionHandler, query);

	MissionInfo[playerid][TIME_AMOUNT] = db_get_field_assoc_int(db_result, "timeamount");

	MissionInfo[playerid][WEATHER_ID] = db_get_field_assoc_int(db_result, "weather");
	
	MissionInfo[playerid][NUM_TASKS] = db_get_field_assoc_int(db_result,"numtasks");
		
	if(MissionInfo[playerid][TIME_AMOUNT] > 0)
	{
	
		MissionInfo[playerid][IS_TIMER] = true;
		
	}
	else
	{

		MissionInfo[playerid][IS_TIMER] = false;

	}
	
	if(MissionInfo[playerid][WEATHER_ID] > 0)
	{ 
		MissionInfo[playerid][IS_WEATHER_DIFFERENT] = true;		
	}
	else
	{		
		MissionInfo[playerid][IS_WEATHER_DIFFERENT] = false;
	}
	
	db_free_result(db_result);

	ApplyMissionProperties(playerid);

	LoadPlayerTask(playerid);
}




forward LoadPlayerTask(playerid);
public LoadPlayerTask(playerid) //used to load info from the .db into missioninfo var but not start the task yet
{

	/*=====================================================
	
	--task type and relevant mission info are changed here
	--called everytime a task is ended
	--tasknum is incremented here and checked if it passes available tasks in the mission
	--if it is passed we call OnMissionComplete(playerid)
	--load sql task no. into TaskInfo and call Initialise task
	--InitialiseTask(playerid,mission,task_type)

	
	=====================================================*/


	MissionInfo[playerid][ON_TASK_COUNT]++;

	if (MissionInfo[playerid][NUM_TASKS] < MissionInfo[playerid][ON_TASK_COUNT]) //if player has completed all tasks, tasks start from number 1
	{
		//OnMissionCompletion(playerid,status);

		//on mission completion callback is called here and in other two places, when time runs out and in case player dies

		ResetEverythingForPlayer(playerid,MissionInfo[playerid][MISSION_NAME],1,MissionInfo[playerid][TIME_AMOUNT]);

		
		return 0;

	}

	LoadTInfoToPlayer(playerid);


	return 1;
}


forward LoadTInfoToPlayer(playerid);

public LoadTInfoToPlayer(playerid) //load task stuff into player vars each cycle
{
	new query[300];

	format(query, sizeof query, "SELECT `tasktype`,`mapobjid`,`posx`,`posy`,`posz`,`taskinfo`,`infostyle`,`rewardcash`,`rewardskin`,`rewardwep` FROM '%s' WHERE `taskid` = '%d' ",MissionInfo[playerid][MISSION_NAME], MissionInfo[playerid][ON_TASK_COUNT]);
	
	new DBResult:db_result = db_query(MissionHandler, query);

	MissionInfo[playerid][TASK_TYPE] = db_get_field_assoc_int(db_result,"tasktype");

	TaskInfo[playerid][MAP_OBJ_ID] = db_get_field_assoc_int(db_result,"mapobjid");

	TaskInfo[playerid][POS_X] = db_get_field_assoc_float(db_result,"posx");
	TaskInfo[playerid][POS_Y] = db_get_field_assoc_float(db_result,"posy");
	TaskInfo[playerid][POS_Z] = db_get_field_assoc_float(db_result,"posz");

	db_get_field_assoc(db_result,"taskinfo",TaskInfo[playerid][TASK_INFO], TASK_INFO_LEN);

	TaskInfo[playerid][TEXT_STYLE] = db_get_field_assoc_int(db_result,"infostyle");

	PlayerTextDrawSetString(playerid,Textdraw1[playerid], TaskInfo[playerid][TASK_INFO]);
	PlayerTextDrawSetString(playerid,Textdraw2[playerid], TaskInfo[playerid][TASK_INFO]);


	TaskInfo[playerid][GIVE_REWARD_CASH] = db_get_field_assoc_int(db_result,"rewardcash");

	TaskInfo[playerid][GIVE_REWARD_SKIN] = db_get_field_assoc_int(db_result,"rewardskin");

	TaskInfo[playerid][GIVE_REWARD_WEP_ID] = db_get_field_assoc_int(db_result,"rewardwep");


	switch(MissionInfo[playerid][TASK_TYPE]) //load appropriate tasktype var into taskinfo 
	{
		case FIND_OBJ,FIND_HIDDEN_OBJ:
		{

			format(query, sizeof query, "SELECT `objid` FROM '%s' WHERE `taskid` = '%d' ",MissionInfo[playerid][MISSION_NAME], MissionInfo[playerid][ON_TASK_COUNT]);
	
			db_result = db_query(MissionHandler, query);

			TaskInfo[playerid][OBJ_ID] = db_get_field_assoc_int(db_result,"objid");

			TaskInfo[playerid][PICKUP_ID] = db_get_field_assoc_int(db_result,"objid");

		}
		case ENTER_HIDDEN_VEH,ENTER_VEH:
		{

			format(query, sizeof query, "SELECT `vehid`,`rot` FROM '%s' WHERE `taskid` = '%d' ",MissionInfo[playerid][MISSION_NAME], MissionInfo[playerid][ON_TASK_COUNT]);
	
			db_result = db_query(MissionHandler, query);

			TaskInfo[playerid][VEH_ID] = db_get_field_assoc_int(db_result,"vehid");

			TaskInfo[playerid][ROT] = db_get_field_assoc_float(db_result, "rot");
		}
		case TASK_GOTO_ACTOR,TASK_TALK_TO_ACTOR,TASK_KILL_ACTOR:
		{
			format(query, sizeof query, "SELECT `objid`,`rot` FROM '%s' WHERE `taskid` = '%d' ",MissionInfo[playerid][MISSION_NAME], MissionInfo[playerid][ON_TASK_COUNT]);
	
			db_result = db_query(MissionHandler, query);

			TaskInfo[playerid][ACTOR] = db_get_field_assoc_int(db_result,"objid");

			TaskInfo[playerid][ROT] = db_get_field_assoc_float(db_result, "rot");

		}
	}
	
	db_free_result(db_result);

	CallRemoteFunction("OnTaskStart","isi",playerid,MissionInfo[playerid][MISSION_NAME],MissionInfo[playerid][TASK_TYPE]);

	InitialiseTask(playerid);
	
}



forward InitialiseTask(playerid);

public InitialiseTask(playerid) //used to initialise creating tasks and start task for player
{
	//native functions interacting with player are activated here

	//1) declare task_info
	//2) create necessary items

	//activate taskinfo msg here and create necessary items to indicate player what to do !

	ShowPlayerTaskInfo(playerid);
	switch(MissionInfo[playerid][TASK_TYPE])
	{
		case ARRIVE_DEST: //to get to a position of checkpoint marked on radar
		{
			if(IsPlayerInAnyVehicle(playerid)) //if race checkpoint, make the checkpoint bigger than usual
			{
				TaskInfo[playerid][OBJ_ID] = CreateDynamicCP(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , 12.0,.playerid = playerid);
			}
			else
			{
				TaskInfo[playerid][OBJ_ID] = CreateDynamicCP(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , 6.0,.playerid = playerid);
			}

			TaskInfo[playerid][MAP_OBJ_ID] = CreateDynamicMapIcon(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , TaskInfo[playerid][MAP_OBJ_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL, .playerid = playerid);
		}
		case FIND_OBJ: //to pickup an object also marked on radar
		{
			TaskInfo[playerid][MAP_OBJ_ID] = CreateDynamicMapIcon(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , TaskInfo[playerid][MAP_OBJ_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL,.playerid = playerid);
			
			new tempid = TaskInfo[playerid][PICKUP_ID];
			
			TaskInfo[playerid][PICKUP_ID] = CreateDynamicPickup(tempid, 8, TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],.playerid = playerid);
		
			TaskInfo[playerid][PICKUP_ID_THRU_VEH] = CreateDynamicPickup(tempid, 14, TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],.playerid = playerid);

		}

		case ENTER_HIDDEN_VEH: //to get into vehicle not set on radar
		{
			
			TaskInfo[playerid][VEH_ID] = CreateVehicle(TaskInfo[playerid][VEH_ID], TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z], TaskInfo[playerid][ROT], -1,-1, -1);

		}

		case FIND_HIDDEN_OBJ: //hidden pickup to pick up without radar markup
		{

			new tempid = TaskInfo[playerid][PICKUP_ID];

			TaskInfo[playerid][PICKUP_ID] = CreateDynamicPickup(tempid, 3, TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],.playerid = playerid);
		
			TaskInfo[playerid][PICKUP_ID_THRU_VEH] = CreateDynamicPickup(tempid, 14, TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],.playerid = playerid);


		}
		case ENTER_VEH: //marked on map 
		{ 
			TaskInfo[playerid][MAP_OBJ_ID] = CreateDynamicMapIcon(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , TaskInfo[playerid][MAP_OBJ_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL,.playerid = playerid);

			TaskInfo[playerid][VEH_ID] = CreateVehicle(TaskInfo[playerid][VEH_ID], TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z]+2, TaskInfo[playerid][ROT], -1, -1, -1);
		
			TaskInfo[playerid][ATTACH_OBJ] = CreateDynamicObject(19902,TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],0.0,0.0,0.0, .playerid = playerid);

			AttachDynamicObjectToVehicle(TaskInfo[playerid][ATTACH_OBJ],TaskInfo[playerid][VEH_ID], 0.0, 0.0, 1.7,0.0,0.0,0.0);
		}

		case TAKE_VEH_TO_DEST://after getting into a vehicle, take it to a destination destroys vehicle
		{
			
			TaskInfo[playerid][OBJ_ID] = CreateDynamicCP(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , 12.0,.playerid = playerid);

		}
		case TASK_GOTO_ACTOR,TASK_TALK_TO_ACTOR: 
		{
			if(TaskInfo[playerid][ACTOR] == -1)
			{
				TaskInfo[playerid][ACTOR] = CreateDynamicActor(random(311),TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],TaskInfo[playerid][ROT], .playerid = playerid);

			}
			else
			{
				TaskInfo[playerid][ACTOR] = CreateDynamicActor(TaskInfo[playerid][ACTOR],TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],TaskInfo[playerid][ROT], .playerid = playerid);
			}

			TaskInfo[playerid][OBJ_ID] = CreateDynamicCP(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , 1.0,.playerid = playerid);

			TaskInfo[playerid][MAP_OBJ_ID] = CreateDynamicMapIcon(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , TaskInfo[playerid][MAP_OBJ_ID], 0,.streamdistance = 10000.0,.style = MAPICON_GLOBAL,.playerid = playerid);
		
			TaskInfo[playerid][ATTACH_OBJ] = CreateDynamicObject(19902,TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] + 1.0 ,0.0,0.0,0.0, .playerid = playerid);

		}
		case TASK_KILL_ACTOR:
		{

			if(TaskInfo[playerid][ACTOR] == -1)
			{
				TaskInfo[playerid][ACTOR] = CreateDynamicActor(random(311),TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],TaskInfo[playerid][ROT], .invulnerable = 0, .health = TASK_ACTOR_SET_HEALTH,.playerid = playerid);

			}
			else
			{
				TaskInfo[playerid][ACTOR] = CreateDynamicActor(TaskInfo[playerid][ACTOR],TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z],TaskInfo[playerid][ROT], .invulnerable = 0, .health = TASK_ACTOR_SET_HEALTH,.playerid = playerid);
			}
			TaskInfo[playerid][ATTACH_OBJ] = CreateDynamicObject(19902,TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z]+3.0,0.0,0.0,0.0, .playerid = playerid);

			new Float: acthealth;

			GetDynamicActorHealth(TaskInfo[playerid][ACTOR], acthealth);

			TaskInfo[playerid][MAP_OBJ_ID] = CreateDynamicMapIcon(TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z] , TaskInfo[playerid][MAP_OBJ_ID], 0,.streamdistance = 10000.0, .style = MAPICON_GLOBAL, .playerid = playerid);
		
			new text[15]; 

			format(text, sizeof text,"Health: \n %f", acthealth);

			TaskInfo[playerid][ACT_SHOW_HEALTH] = CreateDynamic3DTextLabel(text, 0x00FF00FF,TaskInfo[playerid][POS_X], TaskInfo[playerid][POS_Y], TaskInfo[playerid][POS_Z], 30.0,.playerid = playerid);
		

		}
	} 
} 



forward EndTask(playerid);

public EndTask(playerid) //called to destroy objects and vehs after task completion
{

	switch(MissionInfo[playerid][TASK_TYPE])
	{

		case ARRIVE_DEST: //could be used to reach destintion from vehicle but doesnt destroy vehicle
		{
			DestroyDynamicCP(TaskInfo[playerid][OBJ_ID]);

			DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

			GiveTaskReward(playerid);

		}
		case FIND_OBJ:
		{

			ApplyAnimation(playerid, "BSKTBALL", "BBALL_pickup", 4.1, 0, 1, 1, 0, 2000, 1);

			DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

			DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID]);

			DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID_THRU_VEH]);

			GiveTaskReward(playerid);

		}

		case ENTER_HIDDEN_VEH:
		{
			
			GiveTaskReward(playerid);

		}

		case FIND_HIDDEN_OBJ:
		{

			ApplyAnimation(playerid, "BSKTBALL", "BBALL_pickup", 4.1, 0, 1, 1, 0, 2000, 1);

			DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID]);

			DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID_THRU_VEH]);

			//Te Be Done --> attach that object to players hand 

			GiveTaskReward(playerid);

		}

		case ENTER_VEH:
		{

			DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

			GiveTaskReward(playerid);

		}

		case TAKE_VEH_TO_DEST: //destroys vehicle
		{

			DestroyDynamicCP(TaskInfo[playerid][OBJ_ID]);

			DestroyVehicle(TaskInfo[playerid][VEH_ID]);

			DestroyDynamicObject(TaskInfo[playerid][ATTACH_OBJ]);

			GiveTaskReward(playerid);

		}
		case TASK_GOTO_ACTOR:
		{
			SetPlayerPos(playerid, TaskInfo[playerid][POS_X] + (1.0 * floatsin(-TaskInfo[playerid][ROT],degrees) ) , TaskInfo[playerid][POS_Y] + (1.0 * floatcos(-TaskInfo[playerid][ROT],degrees) ),TaskInfo[playerid][POS_Z] );

			SetPlayerFacingAngle(playerid, 180.0 + TaskInfo[playerid][ROT]);

			ApplyAnimation(playerid, "PED", "ATM", 4.1, 1, 1, 1, 0, 0, 1);

			TaskInfo[playerid][DIALOG_TIMER] = SetTimerEx("DeliverToActorAnim",  2000,0, "i", playerid);
		
		}
		case TASK_TALK_TO_ACTOR: //task actually gets started when player reaches the actor to talk to him.
		{
			PlayerTextDrawHide(playerid, Textdraw1[playerid]);

			SetPlayerSpecialAction(playerid, 0);

			SetPlayerPos(playerid, TaskInfo[playerid][POS_X] + (1.0 * floatsin(-TaskInfo[playerid][ROT],degrees) ) , TaskInfo[playerid][POS_Y] + (1.0 * floatcos(-TaskInfo[playerid][ROT],degrees) ),TaskInfo[playerid][POS_Z] );

			SetPlayerFacingAngle(playerid, 180.0 + TaskInfo[playerid][ROT]);

			ApplyAnimation(playerid, "PED", "IDLE_chat", 4.1, 1, 1, 1, 0, 0, 1);

			ApplyDynamicActorAnimation(TaskInfo[playerid][ACTOR],"GANGS", "prtial_gngtlkG" , 4.1, 1, 1, 1, 0, 0);

			PresentActorDialog(playerid,1);
		} 

		case TASK_KILL_ACTOR:
		{
			DestroyDynamicActor(TaskInfo[playerid][ACTOR]);

			DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

			DestroyDynamic3DTextLabel(TaskInfo[playerid][ACT_SHOW_HEALTH]);

			DestroyDynamicObject(TaskInfo[playerid][ATTACH_OBJ]);

			GiveTaskReward(playerid);
		}
		
	}

	return 1;
}

forward GiveTaskReward(playerid);
public GiveTaskReward(playerid)//after task completion, give specific rewards based on #define REWARD
{

	if(TaskInfo[playerid][GIVE_REWARD_CASH] > 0)
	{

		GivePlayerMoney(playerid, TaskInfo[playerid][GIVE_REWARD_CASH]);
	
	}

	if(TaskInfo[playerid][GIVE_REWARD_WEP_ID] > 0)
	{

		GivePlayerWeapon(playerid, TaskInfo[playerid][GIVE_REWARD_WEP_ID], 500);

	}

	if(TaskInfo[playerid][GIVE_REWARD_SKIN] > 0)
	{

		SetPlayerSkin(playerid, TaskInfo[playerid][GIVE_REWARD_SKIN]);

	}
	else if(TaskInfo[playerid][GIVE_REWARD_SKIN] == -1)
	{
		SetPlayerSkin(playerid, random(311));
	}

	PlayerTextDrawHide(playerid, Textdraw1[playerid]);
	
	PlayerTextDrawHide(playerid, Textdraw2[playerid]);

	//callback Ontaskfinish is called here

	CallRemoteFunction("OnTaskFinish","isi",playerid,MissionInfo[playerid][MISSION_NAME],MissionInfo[playerid][TASK_TYPE]); //called from the main server file


	LoadPlayerTask(playerid); // next task gets loaded all happens in a cyclic way

	return 1;
}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************

//-------------------------------------------------------------------------------------------------------------------

//called to check if player has successfully complted an action relating to a task type....
forward CheckActionCompletion(playerid);

public CheckActionCompletion(playerid) //used to check if player has done an action based on task type
{
	if(MissionInfo[playerid][MISSION_STATUS] == true)
	{
		EndTask(playerid);
	}

} 

//-------------------------------------------------------------------------------------------------------------------
//on task completion call EndTask()

forward DeliverToActorAnim(playerid); //called after TASK_GOTO_ACTOR

public DeliverToActorAnim(playerid)
{
	DestroyDynamicActor(TaskInfo[playerid][ACTOR]);

	DestroyDynamicCP(TaskInfo[playerid][OBJ_ID]);

	DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

	DestroyDynamicObject(TaskInfo[playerid][ATTACH_OBJ]);

	ClearAnimations(playerid);

	GiveTaskReward(playerid);

}


//-------------------------------------------------------------------------------------------------------------------

ResetEverythingForPlayer(playerid,mname[],status,timeleft) //status -> -1 time ran out, 0 failed(disconnected or died), 1 success
{

	if(status == 1)//mission completed successfully
	{
		UpdatePlayerGroupMisStatus(playerid,mname);
	}

	MissionInfo[playerid][MISSION_STATUS] = false;

	KillTimer(MissionInfo[playerid][MISSION_TIMER_VAR]);

	KillTimer(MissionStartDialogTimer[playerid]);

	KillTimer(TaskInfo[playerid][DIALOG_TIMER]);
	
	PlayerTextDrawHide(playerid,TimeTextdraw[playerid]);

	PlayerTextDrawHide(playerid,TextdrawActorDialog[playerid]);

	PlayerTextDrawHide(playerid, Textdraw1[playerid]);

	PlayerTextDrawHide(playerid, Textdraw2[playerid]);

	PlayerTextDrawHide(playerid, TextdrawDialog[playerid]);

	DestroyVehicle(TaskInfo[playerid][VEH_ID]);

	DestroyDynamicObject(TaskInfo[playerid][ATTACH_OBJ]);

	DestroyDynamicMapIcon(TaskInfo[playerid][MAP_OBJ_ID]);

	DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID]);

	DestroyDynamicPickup(TaskInfo[playerid][PICKUP_ID_THRU_VEH]);

	DestroyDynamicCP(TaskInfo[playerid][OBJ_ID]);

	DestroyDynamicActor(TaskInfo[playerid][ACTOR]);

	DestroyDynamic3DTextLabel(TaskInfo[playerid][ACT_SHOW_HEALTH]);

	ClearAnimations(playerid);

	CallRemoteFunction("OnMissionCompletion", "isii",playerid,mname,status,timeleft);

	ResetMissionValues(playerid);

	return 1;

}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************

//-------------------------------------------------------------------------------------------------------------------

/* check if player has activated any of tasks actions and if so, proceed within the mission process cycle*/

 public OnPlayerEnterDynamicCP(playerid, checkpointid)
 {
 	if(MissionInfo[playerid][TASK_TYPE] == 6 || MissionInfo[playerid][TASK_TYPE] == 7)
 	{
 		CheckActionCompletion(playerid);
 	}

 	return 1;
 }


//when player completes a group mission, we need to update his status in db...
UpdatePlayerGroupMisStatus(playerid,mname[])
{
	
	//first check if completed mission is of group mission
	new query[200];

	format(query,sizeof(query),"SELECT DISTINCT `group_name`,`grp_msn_sequence` FROM `mission_vars` WHERE `name`= '%s' and `group_name` is not null )",mname);

	new DBResult: db_result = db_query(MissionHandler, query);

	//the mission player completed is group mission, so update his grp seq in db...
	if(db_num_rows(db_result) != 0)
	{
		new PlayerName[MAX_PLAYER_NAME];

		GetPlayerName(playerid, PlayerName,sizeof(PlayerName));

		new GroupName[24];

		new GroupMisSequence = db_get_field_assoc_int(db_result, "grp_msn_sequence");

		db_get_field_assoc(db_result, "group_name",GroupName,24);

		new PlayerMisQuery[1000];

		//insert into player group relation such that for seq 1 insert and else update vaules...
		format(PlayerMisQuery,sizeof(PlayerMisQuery),"INSERT INTO Player_Group_Relation(PlayerName,group_name,grp_msn_sequence)								\
														SELECT '%s','%s',%d 																				\
														WHERE NOT EXISTS(SELECT 1 FROM Player_Group_Relation WHERE PlayerName = '%s' AND group_name = '%s');\
														\
														UPDATE A 					\
														SET grp_msn_sequence = %d 	\
														FROM Player_Group_Relation A \
														WHERE PlayerName = '%s' AND group_name = '%s'",PlayerName,GroupName,GroupMisSequence,PlayerName,GroupName,GroupMisSequence,PlayerName,GroupName);

		db_free_result(db_query(MissionHandler, PlayerMisQuery));
	}
	
}


CheckIfPlayerEligibleForMission(playerid,MissionIndex)
{
	

	//check if mission in a group or not

	//if not allow else

	//check if player is on right mission group order or on 1st mission order of that group

	//-------------------------------------------------------------------------------------


	new query[400];

	new PlayerName[MAX_PLAYER_NAME];

	GetPlayerName(playerid, PlayerName,sizeof(PlayerName));

	new GroupName[24];


	//Get group name and seq number of the input mission...
	format(query,sizeof(query),"SELECT DISTINCT `group_name`,`grp_msn_sequence` FROM `mission_vars` WHERE `name`= '%s' and `group_name` is not null ",MissionStartInfo[MissionIndex][MISSION_NAME]);

	new DBResult: db_result = db_query(MissionHandler, query);

	new GroupMisSequence = db_get_field_assoc_int(db_result, "grp_msn_sequence");

	db_get_field_assoc(db_result, "group_name",GroupName,24);

	if(db_num_rows(db_result) == 0)
	{
		//no group mission, so allow player to play it...
		return 1;
	}
	else
	{
		//Check if player has completed max msn seq inside the group or not....
		format(query,sizeof(query),"SELECT * \
			FROM  \
			(	 \
				SELECT group_name,MAX(grp_msn_sequence) AS MaxGrpSeqPerGroup  \
				FROM `mission_vars`  \
				WHERE `group_name` = '%s' \
			) AS MainMsnGroup	\
			WHERE NOT EXISTS 	\
			(SELECT * FROM Player_Group_Relation WHERE PlayerName = '%s' AND group_name = MainMsnGroup.group_name AND MainMsnGroup.MaxGrpSeqPerGroup = grp_msn_sequence)",GroupName,PlayerName);

		db_result = db_query(MissionHandler, query);

		//player hasn't completed all misions in that group, so we allow to condition next...
		if(db_num_rows(db_result)  != 0)
		{		

			if(GroupMisSequence == 1)//first mission in that group, player should be allowed to play it
			{
				return 1;
			}
			else
			{
				//player is choosing the right order mission to complete, allow him to play...
				new PlayerMisQuery[200];
	
				format(PlayerMisQuery,sizeof(PlayerMisQuery),"SELECT * FROM Player_Group_Relation WHERE PlayerName = '%s' and group_name = '%s' and grp_msn_sequence = %d",PlayerName,GroupName,GroupMisSequence-1);
	
				new DBResult: PlayerMisResult = db_query(MissionHandler, PlayerMisQuery);
	
				if(db_num_rows(PlayerMisResult) == 1)
				{
					return 1;
				}

			}

		}

	}

	return 0;

}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************


public OnPlayerEnterDynamicArea(playerid, areaid)
{
	if(MissionInfo[playerid][MISSION_STATUS] == false)
	{
		for(new index = 0; index<MAX_MISSIONS; index++)
		{
			if(CheckIfPlayerEligibleForMission(playerid,index) == 0)
			{
				SendClientMessage(playerid,MISSION_SEND_PLAYER_MSG_COLOR,"You don't have access to this mission!");

				break;
			}

			if(areaid == MissionStartInfo[index][MISSION_ID] && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT && CheckIfPlayerEligibleForMission(playerid,index) == 1) //player should be on foot to start mission
			{

				PlayerChoseMission[playerid] = index;

				new str[80];

				format(str, sizeof(str), "%sDo you want to start the mission:{00AB18} %s ?", str,MissionStartInfo[index][MISSION_NAME]);

				ShowPlayerDialog(playerid, START_MISSION_DIALOG_BOX, DIALOG_STYLE_MSGBOX, "MISSION", str, "Accept", "Cancel");
						
			}
		}
	}
	else 
	{
		
		SendClientMessage(playerid,MISSION_SEND_PLAYER_MSG_COLOR,"You are already on another mission! Complete it First or opt out of it!");
	
	}
}



public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{

	switch(dialogid)
	{
		case START_MISSION_DIALOG_BOX:
		{

			if(response) //player accepted the mission to do it...
			{
				new index = PlayerChoseMission[playerid];
				
				if(AllowGlobalMission[playerid] == true)
				{
					MissionInfo[playerid][MISSION_STATUS] = true;
					
					switch(MissionStartInfo[index][START_TYPE])
					{
						case MISSION_START_CHECKPOINT:
						{

							LoadMissionOnStart(playerid,MissionStartInfo[index][MISSION_NAME]);

						}
						case MISSION_START_TALK_PHONE:
						{
							SetPlayerSpecialAction(playerid, 11);
							PresentDialog(playerid,index,1);
						}
						case MISSION_START_TALK_NPC:
						{
							SetPlayerPos(playerid, MissionStartInfo[index][POS_X] + ( floatsin(-MissionStartInfo[index][ACTROT], degrees) * 1.0 ),MissionStartInfo[index][POS_Y] + ( floatcos(-MissionStartInfo[index][ACTROT], degrees) * 1.0 ),MissionStartInfo[index][POS_Z]);

							SetPlayerFacingAngle(playerid, 180.0 + MissionStartInfo[index][ACTROT]);

							ApplyAnimation(playerid, "PED", "IDLE_chat", 4.1, 1, 1, 1, 0, 0, 1);

							ApplyDynamicActorAnimation(MissionStartInfo[index][START_ACTOR_ID],"GANGS", "prtial_gngtlkG" , 4.1, 1, 1, 1, 0, 0);

							PresentDialog(playerid,index,1);
						}
					
					}
				} 
				else
				{

					SendClientMessage(playerid,MISSION_SEND_PLAYER_MSG_COLOR,"This mission is locked for you!");
		
				}
			}
			else
			{
				SendClientMessage(playerid,MISSION_SEND_PLAYER_MSG_COLOR,"pressed cancel for mission!");

			}
			
		}
	}

	return 0;
}


//-------------------------------------------------------------------------------------------------------------------


public OnPlayerGiveDamageDynamicActor(playerid, actorid, Float:amount, weaponid, bodypart)
{
	/*=====================================================
	
	we check if player is attacking npc as his task and play out the scenario of npc losing health...
	
	=====================================================*/

	if(MissionInfo[playerid][MISSION_STATUS] == true && MissionInfo[playerid][TASK_TYPE] == 8  && actorid == TaskInfo[playerid][ACTOR])
	{

		new Float:health,x,y,z;

		GetDynamicActorHealth(actorid, Float:health);

		GetDynamicActorPos(actorid, Float:x, Float:y, Float:z);

		health = health - amount;
	
		new text[30];

		format(text, sizeof text,"Health: \n %f", health);

		if (health > 20.0)
		{
			UpdateDynamic3DTextLabelText(TaskInfo[playerid][ACT_SHOW_HEALTH], 0x00FF00FF, text);

			SetDynamicActorHealth(TaskInfo[playerid][ACTOR], health);

		} 
		else
		{

			UpdateDynamic3DTextLabelText(TaskInfo[playerid][ACT_SHOW_HEALTH], 0xFF0000FF, text);

			SetDynamicActorHealth(TaskInfo[playerid][ACTOR], health);

		}

		if(health < 1.0)
		{
			EndTask(playerid);
		}
	}


}


forward AllowPlayerForMission(playerid,bool:check);

public AllowPlayerForMission(playerid,bool:check)
{
	
	AllowGlobalMission[playerid] = check;
	
	
}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************


/**==================================================================

 * Main callbacks which will initialise and set things accordingly...

==================================================================*/


public OnFilterScriptInit()
{

	MissionHandler = db_open("DYOMP.db");
	
	LoadAllMissionPoints();

	print("\n--------------------------------------");
	print("DYOMP by Zeldris");
	print("--------------------------------------\n");

	print("All missions have been loaded successfully");

	return 1;
}


public OnFilterScriptExit()
{
	db_close(MissionHandler);
	
	for(new i = 0; i< MAX_PLAYERS; i++)
	{

		PlayerTextDrawDestroy(i,Textdraw1[i]);
		PlayerTextDrawDestroy(i,Textdraw2[i]);
		PlayerTextDrawDestroy(i,TimeTextdraw[i]);
		PlayerTextDrawDestroy(i,TextdrawDialog[i]);
		PlayerTextDrawDestroy(i,TextdrawActorDialog[i]);
	}
	return 1;
}


public OnPlayerConnect(playerid)
{

	Textdraw1[playerid] = CreatePlayerTextDraw(playerid,326.000000, 369.000000, "_");
	PlayerTextDrawAlignment(playerid,Textdraw1[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,Textdraw1[playerid], 255);
	PlayerTextDrawFont(playerid,Textdraw1[playerid], 1);
	PlayerTextDrawLetterSize(playerid,Textdraw1[playerid], 0.310000, 2.499999);
	PlayerTextDrawColor(playerid,Textdraw1[playerid], -1);
	PlayerTextDrawSetOutline(playerid,Textdraw1[playerid], 0);
	PlayerTextDrawSetProportional(playerid,Textdraw1[playerid], 1);
	PlayerTextDrawSetShadow(playerid,Textdraw1[playerid], 2);
	PlayerTextDrawSetSelectable(playerid,Textdraw1[playerid], 0);

	Textdraw2[playerid] = CreatePlayerTextDraw(playerid,442.000000, 160.000000, "_");
	PlayerTextDrawBackgroundColor(playerid,Textdraw2[playerid], 255);
	PlayerTextDrawFont(playerid,Textdraw2[playerid], 1);
	PlayerTextDrawLetterSize(playerid,Textdraw2[playerid], 0.500000, 1.899999);
	PlayerTextDrawColor(playerid,Textdraw2[playerid], -1);
	PlayerTextDrawSetOutline(playerid,Textdraw2[playerid], 1);
	PlayerTextDrawSetProportional(playerid,Textdraw2[playerid], 1);
	PlayerTextDrawUseBox(playerid,Textdraw2[playerid], 1);
	PlayerTextDrawBoxColor(playerid,Textdraw2[playerid], 199);
	PlayerTextDrawTextSize(playerid,Textdraw2[playerid], 592.000000, 396.000000);
	PlayerTextDrawSetSelectable(playerid,Textdraw2[playerid], 0);


	TimeTextdraw[playerid] = CreatePlayerTextDraw(playerid,81.000000, 196.000000, "_");
	PlayerTextDrawAlignment(playerid,TimeTextdraw[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,TimeTextdraw[playerid], 255);
	PlayerTextDrawFont(playerid,TimeTextdraw[playerid], 1);
	PlayerTextDrawLetterSize(playerid,TimeTextdraw[playerid], 0.439999, 2.099998);
	PlayerTextDrawColor(playerid,TimeTextdraw[playerid], -1);
	PlayerTextDrawSetOutline(playerid,TimeTextdraw[playerid], 1);
	PlayerTextDrawSetProportional(playerid,TimeTextdraw[playerid], 1);
	PlayerTextDrawUseBox(playerid,TimeTextdraw[playerid], 1);
	PlayerTextDrawBoxColor(playerid,TimeTextdraw[playerid], 150);
	PlayerTextDrawTextSize(playerid,TimeTextdraw[playerid], 52.000000, 118.000000);
	PlayerTextDrawSetSelectable(playerid,TimeTextdraw[playerid], 0);

	TextdrawDialog[playerid] = CreatePlayerTextDraw(playerid,338.000000, 347.000000, "_");
	PlayerTextDrawAlignment(playerid,TextdrawDialog[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,TextdrawDialog[playerid], 255);
	PlayerTextDrawFont(playerid,TextdrawDialog[playerid], 1);
	PlayerTextDrawLetterSize(playerid,TextdrawDialog[playerid], 0.349999, 2.299998);
	PlayerTextDrawColor(playerid,TextdrawDialog[playerid], -1);
	PlayerTextDrawSetOutline(playerid,TextdrawDialog[playerid], 0);
	PlayerTextDrawSetProportional(playerid,TextdrawDialog[playerid], 1);
	PlayerTextDrawSetShadow(playerid,TextdrawDialog[playerid], 2);
	PlayerTextDrawUseBox(playerid,TextdrawDialog[playerid], 1);
	PlayerTextDrawBoxColor(playerid,TextdrawDialog[playerid], 0);
	PlayerTextDrawTextSize(playerid,TextdrawDialog[playerid], -13.000000, 365.000000);
	PlayerTextDrawSetSelectable(playerid,TextdrawDialog[playerid], 0);

	TextdrawActorDialog[playerid] = CreatePlayerTextDraw(playerid,338.000000, 347.000000, "_");
	PlayerTextDrawAlignment(playerid,TextdrawActorDialog[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,TextdrawActorDialog[playerid], 255);
	PlayerTextDrawFont(playerid,TextdrawActorDialog[playerid], 1);
	PlayerTextDrawLetterSize(playerid,TextdrawActorDialog[playerid], 0.349999, 2.299998);
	PlayerTextDrawColor(playerid,TextdrawActorDialog[playerid], -1);
	PlayerTextDrawSetOutline(playerid,TextdrawActorDialog[playerid], 0);
	PlayerTextDrawSetProportional(playerid,TextdrawActorDialog[playerid], 1);
	PlayerTextDrawSetShadow(playerid,TextdrawActorDialog[playerid], 2);
	PlayerTextDrawUseBox(playerid,TextdrawActorDialog[playerid], 1);
	PlayerTextDrawBoxColor(playerid,TextdrawActorDialog[playerid], 0);
	PlayerTextDrawTextSize(playerid,TextdrawActorDialog[playerid], -13.000000, 365.000000);
	PlayerTextDrawSetSelectable(playerid,TextdrawActorDialog[playerid], 0);

	
	return 1;
}


public OnPlayerPickUpDynamicPickup(playerid,pickupid)
{
	if(MissionInfo[playerid][TASK_TYPE] == 1 || MissionInfo[playerid][TASK_TYPE] == 3) // no need to check if player already in a mission, it gets checked in CheckActionCompletion
	{
		CheckActionCompletion(playerid);
		
	}
	return 1;
}



public OnPlayerEnterCheckpoint(playerid)
{

	if(MissionInfo[playerid][TASK_TYPE] == 0 || MissionInfo[playerid][TASK_TYPE] == 5)
	{
		CheckActionCompletion(playerid);
		
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(oldstate == PLAYER_STATE_ONFOOT && GetPlayerVehicleID(playerid) == TaskInfo[playerid][VEH_ID]  && newstate == PLAYER_STATE_DRIVER  && (MissionInfo[playerid][TASK_TYPE] == 2 || MissionInfo[playerid][TASK_TYPE] == 4) ) // Player entered a vehicle as a driver
    {
        CheckActionCompletion(playerid);
    }
  
    return 1;
}


public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{

	for(new i= 0;i <MAX_PLAYERS;i++) //to detect if other players are tampering with OnMission players vehicle
	{
		if(MissionInfo[i][MISSION_STATUS] == true && TaskInfo[i][VEH_ID] == vehicleid && i != playerid) //the second condition makes sure player entered on mission player vehicle, third condition its not his on mission vehicle
		{
			RemovePlayerFromVehicle(playerid);
			SendClientMessage(playerid,0xFFFF00FF,"You are not allowed in this vehicle!");
			break;
		}
		
	}
	if(MissionInfo[playerid][MISSION_STATUS] == true && TaskInfo[playerid][VEH_ID] != vehicleid) //to check if on mission player is entering some random vehicle which he shouldnt
	{
		RemovePlayerFromVehicle(playerid);
		SendClientMessage(playerid,0xFFFF00FF,"You are on a Mission, you are not allowed to enter this vehicle!");
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(MissionInfo[playerid][MISSION_STATUS] == true && TaskInfo[playerid][VEH_ID] == vehicleid)
	{
		SendClientMessage(playerid,0xFFFF00FF,"You cannot exit this vehicle right now, complete the {FFF000} mission!");
		PutPlayerInVehicle(playerid, TaskInfo[playerid][VEH_ID], 0);

	}
}



public OnPlayerDisconnect(playerid, reason)
{
	if(MissionInfo[playerid][MISSION_STATUS] == true)
	{

		ResetEverythingForPlayer(playerid,MissionInfo[playerid][MISSION_NAME],0,0);

	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(MissionInfo[playerid][MISSION_STATUS] == true)
	{
		ResetEverythingForPlayer(playerid,MissionInfo[playerid][MISSION_NAME],0,0);

	}
	return 1;
}

//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************
//***********************************************************************************************************************************************

//==========================================================================================

forward StartMissionForPlayer(playerid,mname[]);

public StartMissionForPlayer(playerid,mname[])
{
	LoadMissionOnStart(playerid, mname);
}

