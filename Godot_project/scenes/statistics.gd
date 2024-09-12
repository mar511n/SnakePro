extends Panel

@onready var detail_stats = $TabContainer/Detailed/RichTextLabel
@onready var WinsT = $TabContainer/Session/HFlowContainer/WinsTrophy
@onready var KillsT = $TabContainer/Session/HFlowContainer/KillsTrophy
@onready var HeadshotT = $TabContainer/Session/HFlowContainer/HeadshotTrophy
@onready var BotT = $TabContainer/Session/HFlowContainer/BotTrophy
@onready var FartT = $TabContainer/Session/HFlowContainer/FartTrophy
@onready var SkillT = $TabContainer/Session/HFlowContainer/SkillTrophy
@onready var StdT = $TabContainer/Session/HFlowContainer/StupiddeathsTrophy
# peer_id -> playerstats
var session_stats = {}

func update_stats():
	#print("Global.player_stats")
	#print(Global.player_stats)
	#print("Global.own_player_stats")
	#print(Global.own_player_stats)
	
	session_stats = {-1:{}}
	if Global.player_stats.size() > 0:
		for peer_id in Global.player_stats[-1]:
			session_stats[peer_id] = {}
		for pl_stats in Global.player_stats:
			for peer_id in pl_stats:
				session_stats[peer_id] = Global.merge_player_stats(session_stats[peer_id],pl_stats[peer_id])
	
	#print("session_stats")
	#print(session_stats)
	
	# make detailed tab
	detail_stats.clear()
	detail_stats.append_text("[b][u]All Time stats[/u] of [/b]")
	write_stats_to_RTLabel(Global.own_player_stats,Lobby.player_info.get("name",""),-1,detail_stats)
	detail_stats.append_text("[b][u]Session stats[/u][/b]\n")
	for pl in session_stats:
		var pname = Lobby.players.get(pl, {}).get("name","")
		if pl == -1:
			pname = Lobby.player_info.get("name","")
		if pname != "":
			write_stats_to_RTLabel(session_stats[pl],pname,pl,detail_stats)
	
	# make session tab
	var win_s = []
	var kill_s = []
	var shot_s = []
	var bot_s = []
	var fart_s = []
	var skill_s = []
	var std_s = []
	for pl in session_stats:
		var sni = Lobby.players.get(pl,{}).get("snake_tile_idx",-1)
		var pname = Lobby.players.get(pl, {}).get("name","")
		if pl == -1:
			sni = Lobby.player_info.get("snake_tile_idx",-1)
			pname = Lobby.player_info.get("name","")
		
		var pl_col = Color.BLACK
		if sni >= 0 and sni < len(Global.snake_colors):
			pl_col = Global.snake_colors[sni]
		
		if pname != "":
			var pls = session_stats[pl]
			win_s.append([get_wins(pls),pname,pl_col])
			kill_s.append([get_kills_without_self(pls,pl),pname,pl_col])
			shot_s.append([get_kills_of_type(pls,Global.hit_causes.BULLET,pl),pname,pl_col])
			bot_s.append([get_kills_of_type(pls,Global.hit_causes.BOT,pl),pname,pl_col])
			fart_s.append([get_kills_of_type(pls,Global.hit_causes.FART,pl),pname,pl_col])
			skill_s.append([get_kills_of_type(pls,Global.hit_causes.COLLISION,pl)+get_kills_of_type(pls,Global.hit_causes.APPLE_DMG,pl),pname,pl_col])
			std_s.append([get_kills(pls)-get_kills_without_self(pls,pl),pname,pl_col])
	WinsT.set_places(win_s)
	KillsT.set_places(kill_s)
	HeadshotT.set_places(shot_s)
	BotT.set_places(bot_s)
	FartT.set_places(fart_s)
	SkillT.set_places(skill_s)
	StdT.set_places(std_s)

func write_stats_to_RTLabel(pls:Dictionary,pname:String,peer_id:int,RTLabel:RichTextLabel):
	RTLabel.append_text("[b]%s[/b] (%s)\n" % [pname,peer_id])
	
	var kills = get_kills(pls)
	var kills_wo_self = get_kills_without_self(pls,peer_id)
	var deaths = get_deaths(pls)
	var wins = get_wins(pls)
	
	RTLabel.append_text("wins: %s\n" % [wins])
	RTLabel.append_text("self kills: %s\n" % [kills-kills_wo_self])
	RTLabel.append_text("[u]kills[/u]: %s\n" % [kills_wo_self])
	var kill_ts = get_kill_types(pls,peer_id)
	for kill_t in kill_ts:
		RTLabel.append_text("%s kills: %s\n" % [kill_t,kill_ts[kill_t]])
	
	RTLabel.append_text("[u]deaths[/u]: %s\n" % [deaths])
	var death_ts = get_death_types(pls)
	for death_t in death_ts:
		if death_t == Global.hit_cause_names[int(Global.hit_causes.COLLISION)]:
			for coll_t in death_ts[death_t]:
				RTLabel.append_text("%s %s death: %s\n" % [death_t, coll_t,death_ts[death_t][coll_t]])
		else:
			RTLabel.append_text("%s death: %s\n" % [death_t, death_ts[death_t]])
	#return {"kills":kills, "kills_wo_self":kills_wo_self, "deaths":deaths, "wins":wins, "kill_ts":kill_ts, "death_ts":death_ts}

func get_death_types(pls:Dictionary)->Dictionary:
	var death_ts = {}
	for type in Global.hit_cause_list:
		if type == Global.hit_causes.COLLISION:
			death_ts[Global.hit_cause_names[int(type)]] = {}
			for coll_type in Global.collision_list.slice(1):
				death_ts[Global.hit_cause_names[int(type)]][Global.collision_names[int(coll_type)]] = get_death_of_type(pls,type,coll_type)
		else:
			death_ts[Global.hit_cause_names[int(type)]] = get_death_of_type(pls,type)
	return death_ts

func get_death_of_type(pls:Dictionary, type:Global.hit_causes, coll_type:Global.collision=Global.collision.NO)->int:
	var num = 0
	for death in pls.get("deaths",[]):
		if death[0]==type:
			if coll_type == Global.collision.NO or coll_type == death[1].get("type",Global.collision.NO):
				num += 1
	return num

func get_kill_types(pls:Dictionary,_pl:int, wo_self=true)->Dictionary:
	var kill_ts = {}
	for type in Global.hit_cause_list:
		kill_ts[Global.hit_cause_names[int(type)]] = get_kills_of_type(pls,type, wo_self)
	return kill_ts

func get_kills_of_type(pls:Dictionary, type:Global.hit_causes,pl:int, wo_self=true)->int:
	var num = 0
	for kill in pls.get("kills",[]):
		if kill[1]==type and ((not wo_self) or kill[0]!=pl):
			num += 1
	return num

func get_killed_players(pls:Dictionary)->Dictionary:
	var kills = {}
	for kill in pls.get("kills",[]):
		if not kills.has(kill[0]):
			kills[kill[0]] = 0
		kills[kill[0]] += 1
	return kills

func get_kills_without_self(pls:Dictionary,pl:int)->int:
	var num = 0
	for kill in pls.get("kills",[]):
		if kill[0]!=pl:
			num += 1
	return num

func get_kills(pls:Dictionary)->int:
	return len(pls.get("kills",[]))
func get_deaths(pls:Dictionary)->int:
	return len(pls.get("deaths",[]))
func get_wins(pls:Dictionary)->int:
	return pls.get("wins",0)
