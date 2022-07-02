#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

ConVar g_old_tags, g_new_tag, g_color;
char s_old_tags[512], s_new_tag[512], s_tag[][] = {"{01}", "{02}", "{03}", "{04}", "{05}", "{06}", "{07}", "{08}", "{09}", "{0A}", "{0B}", "{0C}", "{0D}", "{0E}", "{0F}", "{10}"}, s_tag_code[][] = { "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0B", "\x0C", "\x0D", "\x0E", "\x0F", "\x10"};
bool b_colorful;
int i_tag;

public Plugin myinfo =
{
    name = "Chat Tag Changer",
    author = "Gold KingZ",
    description = "It allows you to change the specified chat tags.",
    version = "1.0.0", 
    url = "https://github.com/oqyh"
};

public void OnPluginStart()
{
    Get_Cvar();
	
    HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
}

public void OnMapStart()
{
    Get_Cvar();
}

public void Get_Cvar(){
    g_old_tags = CreateConVar("sm_chat_tag_changer_old_tags", "[SM],[Gold KingZ]", "8 tag 64 character (,)");
    g_new_tag = CreateConVar("sm_chat_tag_changer_new_tags", "{04}Gold KingZ {08}| ,{0R}[Gold KingZ]", "8 tag 64 character (,)\n{0R}=>random\n{01}=>white\n{02}=>darkred\n{03}=>purple\n{04}=>green\n{05}=>lightgreen\n{06}=>lime\n{07}=>red\n{08}=>grey\n{09}=>yellow\n{0A}=>bluegrey\n{0B}=>blue\n{0C}=>darkblue\n{0D}=>grey2\n{0E}=>orchid\n{0F}=>lightred\n{10}=>gold");
    g_color = CreateConVar("sm_chat_tag_changer_colorful", "0", "Is the tag colorful? If active, the colors specified in the tag are removed.", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "chat_tag_changer");

    GetConVarString(g_old_tags, s_old_tags, sizeof(s_old_tags));
    GetConVarString(g_new_tag, s_new_tag, sizeof(s_new_tag));
    b_colorful = GetConVarBool(g_color);
    GetTagSettings();

    HookConVarChange(g_old_tags, OnCvarChanged);
    HookConVarChange(g_new_tag, OnCvarChanged);
    HookConVarChange(g_color, OnCvarChanged);
}

public int OnCvarChanged(Handle convar, const char[] oldVal, const char[] newVal)
{
    if(convar == g_old_tags) strcopy(s_old_tags, sizeof(s_old_tags), newVal);
    else if(convar == g_new_tag) strcopy(s_new_tag, sizeof(s_new_tag), newVal);
    else if(convar == g_color) b_colorful = GetConVarBool(convar);
    GetTagSettings();
}

public void GetTagSettings(){
    for(int i = 0; i < sizeof(s_tag_code); i++) ReplaceString(s_new_tag, sizeof(s_new_tag), s_tag[i], (b_colorful ? "" : s_tag_code[i]));
    i_tag = 0;
}

public Action Hook_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(reliable)
    {
        char s_buffer[256], s_tags[8][64];
        PbReadString(msg, "params", s_buffer, sizeof(s_buffer), 0);
        int i_count = ExplodeString(s_old_tags, ",", s_tags, sizeof(s_tags), sizeof(s_tags[]));
        for (int i = 0; i < i_count; i++)
        {
            int i_search = StrContains(s_buffer, s_tags[i]);
            if( i_search >= 0 && i <= 5 ){
                Handle h_pack;
                CreateDataTimer(0.0, SetDataTimer, h_pack);
                WritePackCell(h_pack, playersNum);
                for(int j = 0; j < playersNum; j++) WritePackCell(h_pack, players[j]);
                WritePackString(h_pack, s_buffer);
                ResetPack(h_pack);
                return Plugin_Handled;
            }
        }
    }
    return Plugin_Continue;
}

public Action SetDataTimer(Handle timer, Handle pack)
{
    int i_players_num = ReadPackCell(pack),  i_client, i_count;
    int [] i_players = new int[i_players_num];
    for(int i = 0; i < i_players_num; i++)
    {
        i_client = ReadPackCell(pack);
        if(IsClientInGame(i_client)) i_players[i_count++] = i_client;
    }
    if(i_count < 1) return;
    i_players_num = i_count; 
    char s_buffer[255], s_tags[8][64], s_tag_temp[128];
    ReadPackString(pack, s_buffer, sizeof(s_buffer));
    i_count = ExplodeString(s_new_tag, ",", s_tags, sizeof(s_tags), sizeof(s_tags[]));
    if(i_tag >= i_count) i_tag = 0;
    strcopy(s_tag_temp, sizeof(s_tag_temp), s_tags[i_tag]);
    TrimString(s_tag_temp);
    i_tag++;
    if(b_colorful){
        ReplaceString(s_tag_temp, sizeof(s_tag_temp), "{0R}", "");
        char s_colorful_tag[128];
        for (int i = 0; i < strlen(s_tag_temp); i++){
            if (IsCharSpace(s_tag_temp[i])) Format(s_colorful_tag, sizeof(s_colorful_tag), "%s%c", s_colorful_tag, s_tag_temp[i]);
			else Format(s_colorful_tag, sizeof(s_colorful_tag), "%s%s%c", s_colorful_tag, "{0R}", s_tag_temp[i]);
        }
        strcopy(s_tag_temp, sizeof(s_tag_temp), s_colorful_tag);
    }
    i_count = GetRandomInt(0, sizeof(s_tag_code)-1);
    while(StrContains(s_tag_temp, "{0R}") >= 0){
        ReplaceStringEx(s_tag_temp, sizeof(s_tag_temp), "{0R}", s_tag_code[i_count]);
        i_count++;
        if(i_count >= sizeof(s_tag_code)) i_count = 0;
    }
    Format(s_tag_temp, sizeof(s_tag_temp), " %s\x01", s_tag_temp);
    i_count = ExplodeString(s_old_tags, ",", s_tags, sizeof(s_tags), sizeof(s_tags[]));
    for (int i = 0; i < i_count; i++) {
        int i_search = StrContains(s_buffer, s_tags[i]);
        if( i_search >= 0 && i_search <= 5 ){
            ReplaceStringEx(s_buffer, sizeof(s_buffer), s_tags[i], s_tag_temp);
            break;
        }
    }
    Handle h_bf = StartMessage("SayText2", i_players, i_players_num, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    PbSetInt(h_bf, "ent_idx", -1);
    PbSetBool(h_bf, "chat", true);
    PbSetString(h_bf, "msg_name", s_buffer);
    PbAddString(h_bf, "params", "");
    PbAddString(h_bf, "params", "");
    PbAddString(h_bf, "params", "");
    PbAddString(h_bf, "params", "");
    EndMessage();
} 