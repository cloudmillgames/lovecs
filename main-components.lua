-- ** MAIN components **

-- Components meant for the MAIN ECS rather than the game ECS
-- These are meant for features that are independent of game scenes, and for dev features

CMainPlayerSession = {
	stage = 1,
	score = 0,
	lives = 3
}
MAIN:DefineComponent("plrsession", CMainPlayerSession)
