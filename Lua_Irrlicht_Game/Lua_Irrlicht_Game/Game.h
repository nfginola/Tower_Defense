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

enum
{
    ID_IsNotPickable = 0,
    IDFlag_IsPickable = 1 << 0,
    IDFlag_IsHighlightable = 1 << 1
};


class EventReceiver : public IEventReceiver
{
public:
    virtual bool OnEvent(const SEvent& event);

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

        else if (key == "1") return IsKeyDown(KEY_KEY_1);
        else if (key == "2") return IsKeyDown(KEY_KEY_2);
        else if (key == "3") return IsKeyDown(KEY_KEY_3);
        else if (key == "4") return IsKeyDown(KEY_KEY_4);
        else if (key == "5") return IsKeyDown(KEY_KEY_5);

        else if (key == "6") return IsKeyDown(KEY_KEY_6);
        else if (key == "7") return IsKeyDown(KEY_KEY_7);
        else if (key == "8") return IsKeyDown(KEY_KEY_8);
        else if (key == "9") return IsKeyDown(KEY_KEY_9);
        else if (key == "0") return IsKeyDown(KEY_KEY_0);

        else if (key == "LShift") return IsKeyDown(KEY_LSHIFT);

        else if (key == "ESC") return IsKeyDown(KEY_ESCAPE);

        else return false;

    }

    bool isKeyPressed(const std::string& key)
    {
        if (key == "W") return keyPressedHelper(KEY_KEY_W);
        else if (key == "A") return keyPressedHelper(KEY_KEY_A);
        else if (key == "S") return keyPressedHelper(KEY_KEY_S);
        else if (key == "D") return keyPressedHelper(KEY_KEY_D);
        else if (key == "K") return keyPressedHelper(KEY_KEY_K);
        else if (key == "Q") return keyPressedHelper(KEY_KEY_Q);
        else if (key == "E") return keyPressedHelper(KEY_KEY_E);
        else if (key == "R") return keyPressedHelper(KEY_KEY_R);
        else if (key == "T") return keyPressedHelper(KEY_KEY_T);
        else if (key == "Y") return keyPressedHelper(KEY_KEY_Y);
        else if (key == "U") return keyPressedHelper(KEY_KEY_U);
        else if (key == "I") return keyPressedHelper(KEY_KEY_I);
        else if (key == "O") return keyPressedHelper(KEY_KEY_O);
        else if (key == "P") return keyPressedHelper(KEY_KEY_P);
        else if (key == "F") return keyPressedHelper(KEY_KEY_F);
        else if (key == "G") return keyPressedHelper(KEY_KEY_G);
        else if (key == "H") return keyPressedHelper(KEY_KEY_H);
        else if (key == "J") return keyPressedHelper(KEY_KEY_J);
        else if (key == "K") return keyPressedHelper(KEY_KEY_K);
        else if (key == "L") return keyPressedHelper(KEY_KEY_L);
        else if (key == "Z") return keyPressedHelper(KEY_KEY_Z);
        else if (key == "X") return keyPressedHelper(KEY_KEY_X);
        else if (key == "C") return keyPressedHelper(KEY_KEY_C);
        else if (key == "V") return keyPressedHelper(KEY_KEY_V);
        else if (key == "B") return keyPressedHelper(KEY_KEY_B);
        else if (key == "N") return keyPressedHelper(KEY_KEY_N);
        else if (key == "M") return keyPressedHelper(KEY_KEY_M);

        else if (key == "1") return keyPressedHelper(KEY_KEY_1);
        else if (key == "2") return keyPressedHelper(KEY_KEY_2);
        else if (key == "3") return keyPressedHelper(KEY_KEY_3);
        else if (key == "4") return keyPressedHelper(KEY_KEY_4);
        else if (key == "5") return keyPressedHelper(KEY_KEY_5);

        else if (key == "6") return keyPressedHelper(KEY_KEY_6);
        else if (key == "7") return keyPressedHelper(KEY_KEY_7);
        else if (key == "8") return keyPressedHelper(KEY_KEY_8);
        else if (key == "9") return keyPressedHelper(KEY_KEY_9);
        else if (key == "0") return keyPressedHelper(KEY_KEY_0);

        else if (key == "LShift") return keyPressedHelper(KEY_LSHIFT);

        else if (key == "ESC") return keyPressedHelper(KEY_ESCAPE);

        else return false;
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
    bool m_keyWasPressed[KEY_KEY_CODES_COUNT];

    bool m_lmbPressed = false;
    bool m_lmbDown = false;

    bool m_rmbPressed = false;
    bool m_rmbDown = false;

    bool m_not_held = true;

    bool keyPressedHelper(EKEY_CODE code)
    {
        bool toRet = m_keyWasPressed[code];
        m_keyWasPressed[code] = false;
        return toRet;
    }


};

struct LinInterpMover
{
	vector3df startPos, endPos;
	float elapsedTime = 0.f;
	float maxTime = 0.f;
    float currTime = 0.f;

    bool done = true;
    bool dead = false;

	vector3df Update(float dt, const std::string& id);
	void AssignNextMove(const vector3df& start, const vector3df& end, float max_time);
};

struct WorldObject
{
    std::string name;
    vector3df pos;
    ISceneNode* mesh = nullptr;

    bool meshVisible = true;
    bool bbVisible = false;

    bool dynamic = false;
    LinInterpMover mover;

    void Test()
    {
        std::cout << "Hello!\n";
    }
};

struct Camera
{
    ICameraSceneNode* sceneCam = nullptr;
    bool active = true;
};

struct GUIStaticText
{
    IGUIStaticText* ptr = nullptr;
};

struct GUIButton
{
    IGUIButton* ptr = nullptr;
};

struct GUIScrollbar
{
    IGUIScrollBar* ptr = nullptr;
};

struct GUIListbox
{
    IGUIListBox* ptr = nullptr;
};

struct GUIEditbox
{
    IGUIEditBox* ptr = nullptr;
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
    void ResetLuaState();
    static int ResetLuaStateWrapper(lua_State* L);
  
private:
    bool m_luaShouldReset = false;
	lua_State* L = nullptr;

	// Irrlicht managers
	IrrlichtDevice* m_dev = nullptr;
	IVideoDriver* m_driver = nullptr;
	ISceneManager* m_sMgr = nullptr;
	IGUIEnvironment* m_guiEnv = nullptr;
	ISceneCollisionManager* m_collMan = nullptr;
    EventReceiver m_evRec;

    // FPS
    u32 then;
};

