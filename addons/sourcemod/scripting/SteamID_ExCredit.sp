#include <sourcemod>
#include <console>
#include <adt_array>
#include <regex>

Handle Arr_SteamIDs = null, RegEx_SteamID = null;

#pragma semicolon 1
#pragma newdecls required

ConVar g_VerilecekKredi = null, g_SureKredi = null;

public Plugin myinfo = 
{
	name = "SteamId Ekstra Kredi", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	LoadConfig();
	g_VerilecekKredi = CreateConVar("sm_steamidekstrakredi_kredi", "5", "X Saniye ile kaç kredi kazansın belirlediğiniz oyuncular?", 0, true, 0.0);
	g_SureKredi = CreateConVar("sm_steamekstrakredi_sure", "120", "X Krediyi belirlediğiniz oyuncular kaç saniyede kazansın?", 0, true, 15.0);
}

public void OnMapEnd()
{
	LoadConfig();
}

public void LoadConfig()
{
	if (!CommandExists("sm_krediver") && !CommandExists("sm_givecredits"))
		SetFailState("Kredi verme komutu bulunamadı.");
	
	char Str_RegExpCompileError[256];
	RegexError Num_RegExpError;
	char RegEx_SteamIDPattern[256];
	RegEx_SteamIDPattern = "^(STEAM_\\d:\\d:\\d+)$";
	RegEx_SteamID = CompileRegex(RegEx_SteamIDPattern, 0, Str_RegExpCompileError, sizeof(Str_RegExpCompileError), Num_RegExpError);
	if (RegEx_SteamID == null)
	{
		SetFailState("Error: %d - Derlenemedi! %s", Num_RegExpError, Str_RegExpCompileError);
	}
	Handle File_SteamIDList = OpenFile("addons/sourcemod/configs/dexter/ekstrakredi_steamid.txt", "rt");
	if (File_SteamIDList == null)
	{
		SetFailState("%s dosyası bulunamadı.", "steamids.txt");
	}
	Arr_SteamIDs = CreateArray(256);
	char Str_SteamID[256];
	while (!IsEndOfFile(File_SteamIDList) && ReadFileLine(File_SteamIDList, Str_SteamID, sizeof(Str_SteamID)))
	{
		StripQuotes(Str_SteamID);
		ReplaceString(Str_SteamID, sizeof(Str_SteamID), "\r", "");
		ReplaceString(Str_SteamID, sizeof(Str_SteamID), "\n", "");
		RegexError Num_ErrCode;
		if (MatchRegex(RegEx_SteamID, Str_SteamID, Num_ErrCode) != -1)
		{
			GetRegexSubString(RegEx_SteamID, 0, Str_SteamID, sizeof(Str_SteamID));
			PushArrayString(Arr_SteamIDs, Str_SteamID);
		}
		else
		{
			SetFailState("Bilinmeyen SteamID: %s (%d) !", Str_SteamID, Num_ErrCode);
		}
	}
	delete File_SteamIDList;
}

public void OnClientPostAdminCheck(int client)
{
	char Str_ClientSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, Str_ClientSteamID, sizeof(Str_ClientSteamID));
	int Num_PlayerFound = FindStringInArray(Arr_SteamIDs, Str_ClientSteamID);
	if (Num_PlayerFound >= 0)
	{
		CreateTimer(g_SureKredi.FloatValue, Krediver, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action Krediver(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsClientInGame(client))
	{
		if (CommandExists("sm_krediver"))
		{
			ServerCommand("sm_krediver #%d %d", userid, g_VerilecekKredi.IntValue);
		}
		else if (CommandExists("sm_givecredits"))
		{
			ServerCommand("sm_givecredits #%d %d", userid, g_VerilecekKredi.IntValue);
		}
	}
	else
	{
		LogError("%d: Client not find!", client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
} 