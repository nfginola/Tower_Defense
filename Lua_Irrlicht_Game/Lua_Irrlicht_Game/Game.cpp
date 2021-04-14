#include "Game.h"


enum
{
    ID_IsNotPickable = 0,
    IDFlag_IsPickable = 1 << 0,
    IDFlag_IsHighlightable = 1 << 1
};



//ISceneNode* Game::player_cast_ray(ICameraSceneNode* from)
//{
//    core::line3d<f32> ray;
//    ray.start = from->getPosition();
//    ray.end = ray.start + (from->getTarget() - ray.start).normalize() * 1000.0f;
//
//    core::vector3df intersection;
//    core::triangle3df hitTriangle;
//       
//    return m_collMan->getSceneNodeAndCollisionPointFromRay(
//        ray,
//        intersection,
//        hitTriangle,
//        IDFlag_IsPickable,
//        0);
//}


namespace luaF
{
    static ISceneManager* s_sMgr = nullptr;
    static EventReceiver* s_evRec = nullptr;
    static IVideoDriver* s_driver = nullptr;

    bool check_lua(lua_State* L, int r)
    {
        if (r != LUA_OK) {
            std::string err = lua_tostring(L, -1);
            std::cout << err << '\n';
            return false;
        }
        else
            return true;
    }
    void load_script(lua_State* L, const std::string& fname)
    {
        static std::string script_dir{ "LuaScripts/" };
        if (check_lua(L, luaL_dofile(L, (script_dir + fname).c_str())))
            std::cout << "[C++]: '" << fname << "' successfully started!\n\n\n";
        else
            throw std::runtime_error("Lua script failed to load!");
    }
    void dump_stack(lua_State* L)
    {
        std::cout << "------- STACK DUMP -------\n";
        for (int i = lua_gettop(L); i > 0; i--)
        {
            std::cout << "Index " << i << ": " << lua_typename(L, lua_type(L, i)) << "\n";
        }
        std::cout << "--------------------------\n";
    }
    void pcall_p(lua_State* L, int args, int res, int errFunc)
    {
        if (lua_pcall(L, args, res, errFunc) == LUA_ERRRUN)
        {
            //dump_stack(L);

            // print error message
            if (lua_isstring(L, -1))
                std::cout << lua_tostring(L, -1) << '\n';
            lua_pop(L, 1);	// pop the error message (we dont need it anymore)

            //dump_stack(L);
        }
    }

    WorldObject* checkWO(lua_State* L, int n)
    {
        WorldObject* wo = nullptr;

        void* ptr = luaL_testudata(L, n, "mt_WorldObject");

        if (ptr != nullptr)
            wo = *(WorldObject**)ptr;
        return wo;
    }
    int createWO(lua_State* L)
    {
        std::string name = lua_tostring(L, -1);
        if (name != "")
        {
            WorldObject** wo = reinterpret_cast<WorldObject**>(lua_newuserdata(L, sizeof(WorldObject*)));
            *wo = new WorldObject;
            (*wo)->name = name;

            luaL_getmetatable(L, "mt_WorldObject");
            lua_setmetatable(L, -2);

        }
        else {
            // error
        }
        return 1;
    }
    int destroyWO(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);
        if (wo != nullptr)
        {
            wo->mesh->setVisible(false);
            wo->mesh->setID(0);
            wo->mesh->remove();
            delete wo;
            wo = nullptr;
        }
        std::cout << "[C++] Deleted WO\n";
        return 0;
    }

    int woTest(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);
        wo->Test();


        return 0;
    }

    int woAddSphereMesh(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        float rad = lua_tonumber(L, -1);
        if (rad == 0.f) rad = 1.f;
        
        if (wo->mesh != nullptr) wo->mesh->drop();
        wo->pos = vector3df(0.0, 0.0, 0.0);
        wo->mesh = s_sMgr->addSphereSceneNode(3.f, 16, 0, -1, wo->pos);
        wo->mesh->setMaterialFlag(video::EMF_LIGHTING, false);
        wo->mesh->setID(ID_IsNotPickable);
        wo->mesh->setName(wo->name.c_str());

        std::cout << "Sphere mesh assigned!\n";

        return 0;
    }

    int woAddCubeMesh(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        if (wo->mesh != nullptr) wo->mesh->drop();

        wo->mesh = s_sMgr->addCubeSceneNode();
        wo->mesh->setID(ID_IsNotPickable);
        wo->mesh->setMaterialFlag(video::EMF_LIGHTING, false);
        wo->mesh->setMaterialTexture(0, s_driver->getTexture("resources/textures/moderntile.jpg"));
        wo->mesh->setPosition(vector3df(10.5f, 0.f, 10.5f));      // Default cubes are 10 big
        wo->mesh->setName(wo->name.c_str());

        std::cout << "Cube mesh assigned!\n";

        return 0;
    }

    int woAddTriSelector(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        scene::ITriangleSelector* selector = 0;
        selector = s_sMgr->createTriangleSelectorFromBoundingBox(wo->mesh);
        wo->mesh->setTriangleSelector(selector);
        selector->drop();

        return 0;
    }

    int woSetPosition(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        float x = lua_tonumber(L, -3);
        float y = lua_tonumber(L, -2);
        float z = lua_tonumber(L, -1);

        wo->pos.X = x;
        wo->pos.Y = y;
        wo->pos.Z = z;
        wo->mesh->setPosition(vector3df(x, y, z));

        return 0;
    }

    int woSetScale(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        float x = lua_tonumber(L, -3);
        float y = lua_tonumber(L, -2);
        float z = lua_tonumber(L, -1);

        wo->mesh->setScale(vector3df(x, y, z));

        return 0;
    }

    int woSetTexture(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        io::path fpath = lua_tostring(L, -1);
        wo->mesh->setMaterialTexture(0, s_driver->getTexture(fpath));

        return 0;
    }

    int woGetPosition(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        lua_pushnumber(L, wo->pos.X);
        lua_pushnumber(L, wo->pos.Y);
        lua_pushnumber(L, wo->pos.Z);

        return 3;
    }

    int woToggleBB(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        if (wo->bbVisible)
        {
            wo->mesh->setDebugDataVisible(0);
            wo->bbVisible = false;
        }
        else
        {
            wo->mesh->setDebugDataVisible(irr::scene::EDS_BBOX);
            wo->bbVisible = true;
        }
        return 0;
    }

    int woSetPickable(lua_State* L)
    {
        WorldObject* wo = checkWO(L, 1);

        wo->mesh->setID(IDFlag_IsPickable);
        return 0;
    }

    int woCollides(lua_State* L)
    {
        WorldObject* wo1 = checkWO(L, 2);
        WorldObject* wo2 = checkWO(L, 1);

        bool intersects = wo1->mesh->getTransformedBoundingBox().intersectsWithBox(wo2->mesh->getTransformedBoundingBox());
        lua_pushboolean(L, intersects);
        return 1;
    }

    int woDrawLine(lua_State* L)
    {
        WorldObject* wo1 = checkWO(L, 2);
        WorldObject* wo2 = checkWO(L, 1);

        s_driver->setTransform(video::ETS_WORLD, core::IdentityMatrix);
        s_driver->draw3DLine(wo1->mesh->getAbsolutePosition(), wo2->mesh->getAbsolutePosition(), SColor(255, 255, 0, 0));
        return 0;
    }

    // Input
    int isLMBPressed(lua_State* L)
    {
        bool lmbPressed = s_evRec->isLMBPressed();

        lua_pushboolean(L, lmbPressed);
        return 1;
    }

    int isKeyDown(lua_State* L)
    {
        std::string key = lua_tostring(L, -1);
        bool keyDown = s_evRec->isKeyDown(key);
        lua_pushboolean(L, keyDown);
        return 1;
    }

}

ISceneNode* Game::CastRay(const vector3df& start, vector3df dir)
{
    core::line3d<f32> ray;
    ray.start = start;
    ray.end = ray.start + dir.normalize() * 1000.0f;

    core::vector3df intersection;
    core::triangle3df hitTriangle;

    ISceneNode* ret = m_collMan->getSceneNodeAndCollisionPointFromRay(
        ray,
        intersection,
        hitTriangle,
        IDFlag_IsPickable,
        0);

    return ret;
}

std::string Game::CastRayGetName(const vector3df& start, vector3df dir)
{
    core::line3d<f32> ray;
    ray.start = start;
    ray.end = ray.start + dir.normalize() * 1000.0f;

    core::vector3df intersection;
    core::triangle3df hitTriangle;

    ISceneNode* ret = m_collMan->getSceneNodeAndCollisionPointFromRay(
        ray,
        intersection,
        hitTriangle,
        IDFlag_IsPickable,
        0);

    return ret->getName();
}

Game::Game() : then(0)
{
    // Init Irrlicht
    {
        m_dev = createDevice(
            video::EDT_OPENGL,
            dimension2d<u32>(1280, 720),
            32,
            false,
            false,
            false,
            &m_evRec);     // Pass the event receiver!

        if (!m_dev)
            throw std::runtime_error("Irrlicht device failed to initialize!");

        m_dev->setWindowCaption(L"Tower Defense");

        m_driver = m_dev->getVideoDriver();
        m_sMgr = m_dev->getSceneManager();
        m_guiEnv = m_dev->getGUIEnvironment();
        m_collMan = m_sMgr->getSceneCollisionManager();
        luaF::s_sMgr = m_sMgr;
        luaF::s_evRec = &m_evRec;
        luaF::s_driver = m_driver;
    }
    
    // Init lua state
    L = luaL_newstate();
    luaL_openlibs(L);   // Open std libs

    // Register World Object
    {
        luaL_newmetatable(L, "mt_WorldObject");

        luaL_Reg sWORegs[] =
        {
        { "new", luaF::createWO },
        { "__gc", luaF::destroyWO },
        { "deleteExplicit", luaF::destroyWO },

        { "test", luaF::woTest },

        { "addSphereMesh", luaF::woAddSphereMesh },
        { "addCubeMesh", luaF::woAddCubeMesh },
        { "addCasting", luaF::woAddTriSelector },

        { "setPosition", luaF::woSetPosition },
        { "setScale", luaF::woSetScale },
        { "setTexture", luaF::woSetTexture },

        { "getPosition", luaF::woGetPosition },

        { "toggleBB", luaF::woToggleBB  },
        { "collidesWith", luaF::woCollides  },
        { "drawLine", luaF::woDrawLine  },
        { "setPickable", luaF::woSetPickable },

        { NULL, NULL }
        };

        luaL_setfuncs(L, sWORegs, 0);

        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "WorldObject");
    }

    // Register input functions
    lua_register(L, "is_lmb_pressed", luaF::isLMBPressed);
    lua_register(L, "is_key_down", luaF::isKeyDown);

   
    // Load scripts
    luaF::load_script(L, "Vector.lua");
    luaF::load_script(L, "testscript.lua");
}

Game::~Game()
{
    m_dev->drop();
}

void Game::Run()
{
	Init();

	while (m_dev->run())
	{
        // Work out a frame delta time.
        const u32 now = m_dev->getTimer()->getTime();
        const f32 dt = (f32)(now - then) / 1000.f;  // in sec
        then = now;

        m_driver->beginScene(true, true, SColor(255, 100, 101, 140));

		Update(dt);

        // Draw
        m_sMgr->drawAll();
        m_guiEnv->drawAll();
        m_driver->endScene();
	}
}

void Game::Init()
{
    // call lua init
    lua_getglobal(L, "init");
    if (lua_isfunction(L, -1))
        luaF::pcall_p(L, 0, 0, 0);

    // Init player camera
    {
        m_mainCam = m_sMgr->addCameraSceneNodeFPS();
        m_mainCam->setPosition({ 20, 5, -5 });
        m_mainCam->setID(ID_IsNotPickable);
    }

    // Init cells
    //{
    //    constexpr int xLen = 7;
    //    constexpr int zLen = 7;
    //    for (int x = 0; x < xLen; ++x)
    //    {
    //        for (int z = 0; z < zLen; ++z)
    //        {
    //            scene::ISceneNode* cubeNode = m_sMgr->addCubeSceneNode();
    //            cubeNode->setID(IDFlag_IsPickable);
    //            cubeNode->setMaterialFlag(video::EMF_LIGHTING, false);
    //            cubeNode->setMaterialTexture(0, m_driver->getTexture("resources/textures/moderntile.jpg"));
    //            //cubeNode->setDebugDataVisible(irr::scene::EDS_BBOX);        // draw debug bb
    //            cubeNode->setPosition(vector3df(x * 10.5f, 0.f, z * 10.5f));      // Default cubes are 10 big
    //
    //            // create and assign triangle selector for nodes
    //            if (x < 5)
    //            {
    //                scene::ITriangleSelector* selector = 0;
    //                selector = m_sMgr->createTriangleSelectorFromBoundingBox(cubeNode);
    //                cubeNode->setTriangleSelector(selector);
    //                selector->drop();
    //            }
    //
    //        }
    //    }
    //}
    
    // Init base
    //{
    //    house = m_sMgr->addCubeSceneNode();
    //    house->setID(ID_IsNotPickable);
    //    house->setMaterialFlag(video::EMF_LIGHTING, false);
    //    house->setMaterialTexture(0, m_driver->getTexture("resources/textures/modernbrick.jpg"));
    //    house->setDebugDataVisible(irr::scene::EDS_BBOX);
    //    house->setPosition(vector3df(6.f * 10.5f, 10.f, 0.f));
    //    house->setScale({ 0.7, 1.3, 0.9 });
    //}
    
    // Init enemy
    //{
    //    enemy = m_sMgr->addSphereSceneNode(2.f, 16, 0, 1, { -20.0, 10.0, 0.0 });
    //    enemy->setMaterialFlag(video::EMF_LIGHTING, false);
    //    enemy->setDebugDataVisible(irr::scene::EDS_BBOX);
    //}

    // Get time now
    then = m_dev->getTimer()->getTime();
}

void Game::Update(float dt)
{
    constexpr float MOVEMENT_SPEED = 20.f;

    // Push highlighted node name (raycasted hit node) to lua
    if (highlightedSceneNode)
        lua_pushstring(L, highlightedSceneNode->getName());
    else
        lua_pushstring(L, "");
    lua_setglobal(L, "castTargetName");

    // Lua main update
    lua_getglobal(L, "update");
	if (lua_isfunction(L, -1)) 
    {
		lua_pushnumber(L, dt);
        luaF::pcall_p(L, 1, 0, 0);
	}


    ICameraSceneNode* pcam = m_sMgr->getActiveCamera();
    core::vector3df nodePosition = pcam->getPosition();
    vector3df fwd;
    // Movement (Should be placed in Lua)
    {
        // get directions
        matrix4 mat = pcam->getViewMatrix();        // the world dirs are in COLUMNS (remember transpose of WM)
        fwd = vector3df(mat[2], mat[6], mat[10]).normalize();
        vector3df right = vector3df(mat[0], mat[4], mat[8]).normalize();
        vector3df up = pcam->getUpVector();
        up.normalize();

        if (m_evRec.IsKeyDown(irr::KEY_KEY_W))
            nodePosition += fwd * MOVEMENT_SPEED * dt;
        else if (m_evRec.IsKeyDown(irr::KEY_KEY_S))
            nodePosition -= fwd * MOVEMENT_SPEED * dt;

        if (m_evRec.IsKeyDown(irr::KEY_KEY_A))
            nodePosition -= right * MOVEMENT_SPEED * dt;
        else if (m_evRec.IsKeyDown(irr::KEY_KEY_D))
            nodePosition += right * MOVEMENT_SPEED * dt;

        if (m_evRec.IsKeyDown(irr::KEY_KEY_E))
            nodePosition += up * MOVEMENT_SPEED * dt;
        else if (m_evRec.IsKeyDown(irr::KEY_LSHIFT))
            nodePosition -= up * MOVEMENT_SPEED * dt;
    }

    // Movement bounds (Should be placed in LUA)
    {
        // camera bounds
        if (abs(pcam->getAbsolutePosition().X) > 70 ||
            abs(pcam->getAbsolutePosition().Y) > 70 ||
            abs(pcam->getAbsolutePosition().Z) > 70)
        {
            nodePosition = vector3df(0.0, 20.0, 0.0);
        }
    }

    // Set player position
    pcam->setPosition(nodePosition);

    //// Get distance to enemy from one specific tower
    //{
    //    ISceneNode* tow = m_sMgr->getSceneNodeFromName("tower1", 0);
    //    float dist = 0.f;
    //    if (enemy->isVisible() && tow)
    //    {
    //        dist = (tow->getAbsolutePosition() - enemy->getAbsolutePosition()).getLength();
    //        if (dist < 20)
    //        {
    //            //std::cout << "Dist: " << dist << '\n';
    //            //std::cout << "Select current enemy to shoot at!\n\n";
    //            m_driver->setTransform(video::ETS_WORLD, core::IdentityMatrix);
    //            m_driver->draw3DLine(tow->getAbsolutePosition(), enemy->getAbsolutePosition(), SColor(255, 255, 0, 0));
    //        }
    //    }
    //}
    
    // Check for collision with base
    //{
    //    if (enemy->isVisible() && house && house->getTransformedBoundingBox().intersectsWithBox(enemy->getTransformedBoundingBox()))
    //    {
    //        std::cout << "Lost HP!\n";
    //        enemy->setVisible(false);
    //        //enemy->drop();
    //    }
    //}

    // Move enemy
    //enemy->setPosition(enemy->getPosition() + vector3df(1.0, 0.0, 0.0) * MOVEMENT_SPEED / 2 * dt);

    // Highlight scene nodes that are pickable (This can be here in C++)
    {
        if (highlightedSceneNode)
        {
            highlightedSceneNode->setDebugDataVisible(0);   // reset debug bb
        }

        // Hit ray
        ISceneNode* selectedSceneNode = CastRay(m_mainCam->getPosition(), fwd);
        if (selectedSceneNode)
        {
            highlightedSceneNode = selectedSceneNode;
            selectedSceneNode->setDebugDataVisible(irr::scene::EDS_BBOX);        // draw debug bb

            if (m_evRec.IsKeyDown(EKEY_CODE::KEY_KEY_X))
            {
                selectedSceneNode->setMaterialTexture(0, m_driver->getTexture("resources/textures/modernbrick.jpg"));

            }
            /* if (m_evRec.isLMBPressed())
            {
                float x, y, z;
                x = selectedSceneNode->getAbsolutePosition().X;
                y = selectedSceneNode->getAbsolutePosition().Y;
                z = selectedSceneNode->getAbsolutePosition().Z;
                std::cout << x << ", " << y << ", " << z << '\n';

                vector3df pos = selectedSceneNode->getAbsolutePosition();

                scene::ISceneNode* tower = m_sMgr->addSphereSceneNode();
                tower->setName("tower1");
                tower->setID(IDFlag_IsPickable);
                tower->setMaterialFlag(video::EMF_LIGHTING, false);
                tower->setMaterialTexture(0, m_driver->getTexture("resources/textures/modernbrick.jpg"));
                tower->setPosition(vector3df(pos.X, pos.Y + 10.0, pos.Z));
                tower->setScale({ 0.5f, 2.f, 0.5f });
            }*/
        }
    }
}
