#pragma once
#include <irrlicht.h>
#include <windows.h>
#include <iostream>
#include <string>
#include <assert.h>
#include <lua.hpp>
#include <vector>

using namespace irr;
using namespace core;
using namespace scene;
using namespace video;
using namespace io;
using namespace gui;

class EventReceiver : public IEventReceiver
{
public:
    virtual bool OnEvent(const SEvent& event)
    {
        if (event.EventType == irr::EET_KEY_INPUT_EVENT)
            m_keyIsDown[event.KeyInput.Key] = event.KeyInput.PressedDown;



        if (event.EventType == irr::EET_MOUSE_INPUT_EVENT)
        {
            switch (event.MouseInput.Event)
            {
            case EMIE_LMOUSE_PRESSED_DOWN:
                m_lmbPressed = true;
                m_lmbDown = true;
                break;
            case EMIE_LMOUSE_LEFT_UP:
                m_lmbPressed = false;
                m_lmbDown = false;
                break;

            default:
                break;
            }
        }

        return false;
    }

    // This is used to check whether a key is being held down
    virtual bool IsKeyDown(EKEY_CODE keyCode) const
    {
        return m_keyIsDown[keyCode];
    }

    bool isKeyDown(const std::string& key) const
    {
        if (key == "W") return IsKeyDown(KEY_KEY_W);
        else if (key == "A") return IsKeyDown(KEY_KEY_A);
        else if (key == "S") return IsKeyDown(KEY_KEY_S);
        else if (key == "D") return IsKeyDown(KEY_KEY_D);
        else if (key == "K") return IsKeyDown(KEY_KEY_K);
        else if (key == "Q") return IsKeyDown(KEY_KEY_Q);
        else if (key == "E") return IsKeyDown(KEY_KEY_E);
        else if (key == "R") return IsKeyDown(KEY_KEY_R);
        else if (key == "T") return IsKeyDown(KEY_KEY_T);
        else if (key == "Y") return IsKeyDown(KEY_KEY_Y);
    }

    bool isLMBPressed()
    {
        bool toRet = m_lmbPressed;
        m_lmbPressed = false;
        return toRet;
    }

    bool isLMBDown()
    {
        return m_lmbDown;
    }

    EventReceiver()
    {
        for (u32 i = 0; i < KEY_KEY_CODES_COUNT; ++i)
            m_keyIsDown[i] = false;
    }

private:
    bool m_keyIsDown[KEY_KEY_CODES_COUNT];

    bool m_lmbPressed = false;
    bool m_lmbDown = false;
};

struct LinInterpMover
{
	vector3df start, end;
	float elapsed_time = 0.f;
	float max_time = 0.f;

	void moveThisFrame(float dt);
	void assignNextMove(vector3df start, vector3df end, float max_time);

};

struct WorldObject
{
    std::string name;
    vector3df pos;
    ISceneNode* mesh = nullptr;

    bool bbVisible = false;

    bool dynamic = false;
    LinInterpMover mover;

    void Test()
    {
        std::cout << "Hello!\n";
    }
};

class Game
{
public:
	Game();
	~Game();

	void Run();
	
private:
	void Init();
	void Update(float dt);

    // For Lua
    ISceneNode* CastRay(const vector3df& start, vector3df dir);
    std::string CastRayGetName(const vector3df& start, vector3df dir);

private:
	lua_State* L = nullptr;

	// Irrlicht managers
	IrrlichtDevice* m_dev = nullptr;
	IVideoDriver* m_driver = nullptr;
	ISceneManager* m_sMgr = nullptr;
	IGUIEnvironment* m_guiEnv = nullptr;
	ISceneCollisionManager* m_collMan = nullptr;
    EventReceiver m_evRec;

    // Cam
	ICameraSceneNode* m_mainCam = nullptr;

    // FPS
    u32 then;

    std::vector<WorldObject> m_objects;



    // temp
    //ISceneNode* enemy = nullptr;
    //ISceneNode* house = nullptr;
    ISceneNode* highlightedSceneNode = nullptr;

};

