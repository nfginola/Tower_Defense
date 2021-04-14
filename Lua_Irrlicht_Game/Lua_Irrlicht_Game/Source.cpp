////#include <irrlicht.h>
////#include <windows.h>
////#include <iostream>
////#include <string>
////#include <assert.h>
////
////#include <lua.hpp>
////
////using namespace irr;
////using namespace core;
////using namespace scene;
////using namespace video;
////using namespace io;
////using namespace gui;
//#include "Game.h"
//
//// Movement
//class MyEventReceiver : public IEventReceiver
//{
//public:
//    // This is the one method that we have to implement
//    virtual bool OnEvent(const SEvent& event)
//    {
//        // Remember whether each key is down or up
//        if (event.EventType == irr::EET_KEY_INPUT_EVENT)
//            KeyIsDown[event.KeyInput.Key] = event.KeyInput.PressedDown;
//
//        if (event.EventType == irr::EET_MOUSE_INPUT_EVENT)
//        {
//            switch (event.MouseInput.Event)
//            {
//            case EMIE_LMOUSE_PRESSED_DOWN:
//                lmbPressed = true;
//                lmbDown = true;
//                break;
//            case EMIE_LMOUSE_LEFT_UP:
//                lmbPressed = false;
//                lmbDown = false;
//                break;
//
//            default:
//                break;
//            }
//            //MouseInput = event.MouseInput;
//        }
//
//        return false;
//    }
//
//    // This is used to check whether a key is being held down
//    virtual bool IsKeyDown(EKEY_CODE keyCode) const
//    {
//        return KeyIsDown[keyCode];
//    }
//
//    bool isLMBPressed()
//    {
//        bool toRet = lmbPressed;
//        lmbPressed = false;
//        return toRet;
//    }
//
//    bool isLMBDown()
//    {
//        return lmbDown;
//    }
//
//    MyEventReceiver()
//    {
//        for (u32 i = 0; i < KEY_KEY_CODES_COUNT; ++i)
//            KeyIsDown[i] = false;
//    }
//
//private:
//    // We use this array to store the current state of each key
//    bool KeyIsDown[KEY_KEY_CODES_COUNT];
//    bool lmbPressed = false;
//    bool lmbDown = false;
//
//    //SEvent::SMouseInput MouseInput;
//};
//
//enum
//{
//    // I use this ISceneNode ID to indicate a scene node that is
//    // not pickable by getSceneNodeAndCollisionPointFromRay()
//    ID_IsNotPickable = 0,
//
//    // I use this flag in ISceneNode IDs to indicate that the
//    // scene node can be picked by ray selection.
//    IDFlag_IsPickable = 1 << 0,
//
//    // I use this flag in ISceneNode IDs to indicate that the
//    // scene node can be highlighted.  In this example, the
//    // homonids can be highlighted, but the level mesh can't.
//    IDFlag_IsHighlightable = 1 << 1
//};
//
//void irrlicht_test()
//{
//    MyEventReceiver eventRec;
//
//    IrrlichtDevice* device = createDevice(
//        video::EDT_OPENGL,
//        dimension2d<u32>(1280, 720),
//        32,
//        false,
//        false,
//        false,
//        &eventRec);     // Pass the event receiver!
//
//    if (!device)
//        throw std::runtime_error("Irrlicht device failed to initialize!");
//
//    device->setWindowCaption(L"Hello World! - Irrlicht Engine Demo");
//
//    IVideoDriver* driver = device->getVideoDriver();
//    ISceneManager* smgr = device->getSceneManager();
//    IGUIEnvironment* guienv = device->getGUIEnvironment();
//
//    guienv->addStaticText(L"Hello World! This is the Irrlicht Software renderer!",
//        rect<s32>(10, 10, 650, 80), true);
//
//    auto n = smgr->addCameraSceneNodeFPS();
//    n->setPosition({ 20, 5, -5 });
//    n->setID(ID_IsNotPickable);
//
//    constexpr int xLen = 7;
//    constexpr int zLen = 7;
//    for (int x = 0; x < xLen; ++x)
//    {
//        for (int z = 0; z < zLen; ++z)
//        {
//            scene::ISceneNode* cubeNode = smgr->addCubeSceneNode();
//            cubeNode->setID(IDFlag_IsPickable);
//            cubeNode->setMaterialFlag(video::EMF_LIGHTING, false);
//            cubeNode->setMaterialTexture(0, driver->getTexture("resources/textures/moderntile.jpg"));
//            //cubeNode->setDebugDataVisible(irr::scene::EDS_BBOX);        // draw debug bb
//            cubeNode->setPosition(vector3df(x * 10.5f, 0.f, z * 10.5f));      // Default cubes are 10 big
//            //cubeNode->setTriangleSelector(
//
//            // create and assign triangle selector for nodes
//            if (x < 5)
//            {
//                scene::ITriangleSelector* selector = 0;
//                selector = smgr->createTriangleSelectorFromBoundingBox(cubeNode);
//                cubeNode->setTriangleSelector(selector);
//                selector->drop();
//            }
//
//        }
//    }
//
//    scene::ISceneNode* house = smgr->addCubeSceneNode();
//    house->setID(IDFlag_IsPickable);
//    house->setMaterialFlag(video::EMF_LIGHTING, false);
//    house->setMaterialTexture(0, driver->getTexture("resources/textures/modernbrick.jpg"));
//    house->setDebugDataVisible(irr::scene::EDS_BBOX);
//    house->setPosition(vector3df(6.f * 10.5f, 10.f, 0.f));
//    house->setScale({ 0.7, 1.3, 0.9 });
//
//
//    // Add moving enemy
//    ISceneNode* enemy = smgr->addSphereSceneNode(2.f, 16, 0, 1, { -20.0, 10.0, 0.0 });
//    enemy->setDebugDataVisible(irr::scene::EDS_BBOX);
//
//    scene::ISceneNode* highlightedSceneNode = 0;
//    scene::ISceneCollisionManager* collMan = smgr->getSceneCollisionManager();
//
//    int lastFPS = -1;
//    // In order to do framerate independent movement, we have to know
//    // how long it was since the last frame
//    u32 then = device->getTimer()->getTime();
//
//    constexpr float MOVEMENT_SPEED = 20.f;
//
//    while (device->run())
//    {
//        // Work out a frame delta time.
//        const u32 now = device->getTimer()->getTime();
//        const f32 frameDeltaTime = (f32)(now - then) / 1000.f; // Time in seconds
//        then = now;
//
//        driver->beginScene(true, true, SColor(255, 100, 101, 140));
//
//        ICameraSceneNode* pcam = smgr->getActiveCamera();
//        core::vector3df nodePosition = pcam->getPosition();
//
//        // fvec
//        matrix4 mat = pcam->getViewMatrix();        // the world dirs are in COLUMNS (remember transpose of WM)
//        vector3df fwd = vector3df(mat[2], mat[6], mat[10]).normalize();
//        vector3df right = vector3df(mat[0], mat[4], mat[8]).normalize();
//        vector3df up = pcam->getUpVector();
//        up.normalize();
//
//        enemy->setPosition(enemy->getPosition() + vector3df(1.0, 0.0, 0.0) * MOVEMENT_SPEED / 2 * frameDeltaTime);
//
//        if (eventRec.IsKeyDown(irr::KEY_KEY_W))
//            nodePosition += fwd * MOVEMENT_SPEED * frameDeltaTime;
//        else if (eventRec.IsKeyDown(irr::KEY_KEY_S))
//            nodePosition -= fwd * MOVEMENT_SPEED * frameDeltaTime;
//
//        if (eventRec.IsKeyDown(irr::KEY_KEY_A))
//            nodePosition -= right * MOVEMENT_SPEED * frameDeltaTime;
//        else if (eventRec.IsKeyDown(irr::KEY_KEY_D))
//            nodePosition += right * MOVEMENT_SPEED * frameDeltaTime;
//
//        if (eventRec.IsKeyDown(irr::KEY_KEY_E))
//            nodePosition += up * MOVEMENT_SPEED * frameDeltaTime;
//        else if (eventRec.IsKeyDown(irr::KEY_LSHIFT))
//            nodePosition -= up * MOVEMENT_SPEED * frameDeltaTime;
//
//        // camera bounds
//        if (abs(pcam->getAbsolutePosition().X) > 70 ||
//            abs(pcam->getAbsolutePosition().Y) > 70 ||
//            abs(pcam->getAbsolutePosition().Z) > 70)
//        {
//            nodePosition = vector3df(0.0, 20.0, 0.0);
//        }
//
//        pcam->setPosition(nodePosition);
//
//        // get distance from tower
//        ISceneNode* tow = smgr->getSceneNodeFromName("tower1", 0);
//        float dist = 0.f;
//        if (enemy->isVisible() && tow)
//        {
//            dist = (tow->getAbsolutePosition() - enemy->getAbsolutePosition()).getLength();
//            if (dist < 20)
//            {
//                std::cout << "Dist: " << dist << '\n';
//                std::cout << "Select current enemy to shoot at!\n\n";
//            }
//        }
//
//
//        // collision with house
//        if (enemy->isVisible() && house->getTransformedBoundingBox().intersectsWithBox(enemy->getTransformedBoundingBox()))
//        {
//            std::cout << "Lost HP!\n";
//            enemy->setVisible(false);
//        }
//
//        // Reset the the highlight
//        if (highlightedSceneNode)
//        {
//            highlightedSceneNode->setDebugDataVisible(0);   // reset debug bb
//        }
//
//        core::line3d<f32> ray;
//        ray.start = pcam->getPosition();
//        ray.end = ray.start + (pcam->getTarget() - ray.start).normalize() * 1000.0f;
//
//        // Tracks the current intersection point with the level or a mesh
//        core::vector3df intersection;
//        // Used to show with triangle has been hit
//        core::triangle3df hitTriangle;
//
//        scene::ISceneNode* selectedSceneNode =
//            collMan->getSceneNodeAndCollisionPointFromRay(
//                ray,
//                intersection,
//                hitTriangle,
//                IDFlag_IsPickable,
//                0);
//
//        if (selectedSceneNode)
//        {
//            highlightedSceneNode = selectedSceneNode;
//            selectedSceneNode->setDebugDataVisible(irr::scene::EDS_BBOX);        // draw debug bb
//
//            if (eventRec.isLMBPressed())
//            {
//                float x, y, z;
//                x = selectedSceneNode->getAbsolutePosition().X;
//                y = selectedSceneNode->getAbsolutePosition().Y;
//                z = selectedSceneNode->getAbsolutePosition().Z;
//                std::cout << x << ", " << y << ", " << z << '\n';
//
//                vector3df pos = selectedSceneNode->getAbsolutePosition();
//
//                scene::ISceneNode* tower = smgr->addSphereSceneNode();
//                tower->setName("tower1");
//                tower->setID(IDFlag_IsPickable);
//                tower->setMaterialFlag(video::EMF_LIGHTING, false);
//                tower->setMaterialTexture(0, driver->getTexture("resources/textures/modernbrick.jpg"));
//                tower->setPosition(vector3df(pos.X, pos.Y + 10.0, pos.Z));
//                tower->setScale({ 0.5f, 2.f, 0.5f });
//            }
//        }
//
//
//
//
//
//
//        // Order matters here!
//        smgr->drawAll();
//        guienv->drawAll();
//
//        driver->endScene();
//
//        // get fps
//        int fps = driver->getFPS();
//        if (lastFPS != fps)
//        {
//            core::stringw tmp(L"Movement Example - Irrlicht Engine [");
//            tmp += driver->getName();
//            tmp += L"] fps: ";
//            tmp += fps;
//
//            device->setWindowCaption(tmp.c_str());
//            lastFPS = fps;
//        }
//    }
//
//    device->drop();
//}
//
//bool check_lua(lua_State* L, int r)
//{
//    if (r != LUA_OK) {
//        std::string err = lua_tostring(L, -1);
//        std::cout << err << '\n';
//        return false;
//    }
//    else
//        return true;
//}
//
//void load_script(lua_State* L, const std::string& fname)
//{
//    static std::string script_dir{ "LuaScripts/" };
//    if (check_lua(L, luaL_dofile(L, (script_dir + fname).c_str())))
//        std::cout << "[C++]: '" << fname << "' successfully started!\n\n\n";
//    else
//        throw std::runtime_error("Lua script failed to load!");
//}
//
//void dump_stack(lua_State* L)
//{
//    std::cout << "------- STACK DUMP -------\n";
//    for (int i = lua_gettop(L); i > 0; i--)
//    {
//        std::cout << "Index " << i << ": " << lua_typename(L, lua_type(L, i)) << "\n";
//    }
//    std::cout << "--------------------------\n";
//}
//
//void lua_test()
//{
//    // Init lua state
//    lua_State* L = luaL_newstate();
//    luaL_openlibs(L);   // Open std libs
//
//    load_script(L, "testscript.lua");
//}
//
//int main()
//try
//{
//    lua_test();
//    irrlicht_test();
//
//    return 0;
//}
//catch (std::runtime_error& e)
//{
//    std::cerr << "Error: " << e.what() << '\n';
//    return -1;
//}
//catch (...)
//{
//    std::cerr << "Unhandled exception!\n";
//    return -2;
//}


#include "Game.h"
int main()
try
{
    Game gm;
    gm.Run();

    return 0;
}
catch (std::runtime_error& e)
{
    std::cerr << "Error: " << e.what() << '\n';
    return -1;
}
catch (...)
{
    std::cerr << "Unhandled exception!\n";
    return -2;
}