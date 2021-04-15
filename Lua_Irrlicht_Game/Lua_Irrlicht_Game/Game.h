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
            case EMIE_RMOUSE_PRESSED_DOWN:
                m_rmbPressed = true;
                m_rmbDown = true;
                break;
            case EMIE_RMOUSE_LEFT_UP:
                m_rmbPressed = false;
                m_rmbDown = false;
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
        else if (key == "U") return IsKeyDown(KEY_KEY_U);
        else if (key == "I") return IsKeyDown(KEY_KEY_I);
        else if (key == "O") return IsKeyDown(KEY_KEY_O);
        else if (key == "P") return IsKeyDown(KEY_KEY_P);
        else if (key == "F") return IsKeyDown(KEY_KEY_F);
        else if (key == "G") return IsKeyDown(KEY_KEY_G);
        else if (key == "H") return IsKeyDown(KEY_KEY_H);
        else if (key == "J") return IsKeyDown(KEY_KEY_J);
        else if (key == "K") return IsKeyDown(KEY_KEY_K);
        else if (key == "L") return IsKeyDown(KEY_KEY_L);
        else if (key == "Z") return IsKeyDown(KEY_KEY_Z);
        else if (key == "X") return IsKeyDown(KEY_KEY_X);
        else if (key == "C") return IsKeyDown(KEY_KEY_C);
        else if (key == "V") return IsKeyDown(KEY_KEY_V);
        else if (key == "B") return IsKeyDown(KEY_KEY_B);
        else if (key == "N") return IsKeyDown(KEY_KEY_N);
        else if (key == "M") return IsKeyDown(KEY_KEY_M);

        else if (key == "1") return IsKeyDown(KEY_KEY_0);
        else if (key == "2") return IsKeyDown(KEY_KEY_1);
        else if (key == "3") return IsKeyDown(KEY_KEY_2);
        else if (key == "4") return IsKeyDown(KEY_KEY_3);
        else if (key == "5") return IsKeyDown(KEY_KEY_4);

        else if (key == "6") return IsKeyDown(KEY_KEY_5);
        else if (key == "7") return IsKeyDown(KEY_KEY_6);
        else if (key == "8") return IsKeyDown(KEY_KEY_7);
        else if (key == "9") return IsKeyDown(KEY_KEY_8);
        else if (key == "0") return IsKeyDown(KEY_KEY_9);

        else if (key == "LShift") return IsKeyDown(KEY_LSHIFT);

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

    bool isRMBPressed()
    {
        bool toRet = m_rmbPressed;
        m_rmbPressed = false;
        return toRet;
    }

    bool isRMBDown()
    {
        return m_rmbDown;
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

    bool m_rmbPressed = false;
    bool m_rmbDown = false;
};

struct LinInterpMover
{
	vector3df start, end;
	float elapsed_time = 0.f;
	float max_time = 0.f;

	bool moveThisFrame(float dt);
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

    void Update(float dt)
    {
        if (mover.moveThisFrame(dt))
        {
            // If move done
            // call lua assignNextCoroutine which in turn calls assignNextMove
        }
    }
};

struct Camera
{
    ICameraSceneNode* sceneCam = nullptr;
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

    ISceneNode* CastRay(const vector3df& start, vector3df dir);
  
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
    ISceneNode* highlightedSceneNode = nullptr;

    // FPS
    u32 then;
};

