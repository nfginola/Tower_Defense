#include "Game.h"

enum
{
    ID_IsNotPickable = 0,
    IDFlag_IsPickable = 1 << 0,
    IDFlag_IsHighlightable = 1 << 1
};

namespace luaF
{
    // old
    /* WorldObject* checkWO(lua_State* L, int n)
     {
         void* ptr = luaL_testudata(L, n, "mt_WorldObject");
         WorldObject* wo = nullptr;
         if (ptr != nullptr)
             wo = *(WorldObject**)ptr;
         return wo;
     }*/

    static ISceneManager* s_sMgr = nullptr;
    static EventReceiver* s_evRec = nullptr;
    static IVideoDriver* s_driver = nullptr;
    static ISceneCollisionManager* s_collMan = nullptr;

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

    // Check user data from stack
    template<typename T>
    T* checkObject(lua_State* L, int n, const std::string& metatable)
    {
        void* ptr = luaL_testudata(L, n, metatable.c_str());
        T* obj = nullptr;
        if (ptr != nullptr)
            obj = *(T**)ptr;
        return obj;
    }

    // World object
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
        else
            throw std::runtime_error("No name assigned to WorldObject at creation!");
        return 1;
    }
    // destroy irrlicht node
    int destroyWO(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");
        if (wo != nullptr)
        {
            wo->mesh->remove();
            wo->mesh = nullptr;
        }
        //std::cout << "[C++]: Node removed!\n";
        return 0;
    }   
    int deallocateWO(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        if (wo != nullptr)
        {
            if (wo->mesh != nullptr)
            {
                wo->mesh->remove();
                wo->mesh = nullptr;
            }
            delete wo;
        }
        //std::cout << "[C++]: WO deallocated!\n";

        return 0;
    }

    int woTest(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");
        wo->Test();


        return 0;
    }

    int woAddSphereMesh(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        float rad = lua_tonumber(L, 2);
        if (rad == 0.f) rad = 1.f;
        
        if (wo->mesh != nullptr) wo->mesh->drop();
        wo->pos = vector3df(0.0, 0.0, 0.0);
        wo->mesh = s_sMgr->addSphereSceneNode(rad, 16, 0, -1, wo->pos);
        wo->mesh->setMaterialFlag(video::EMF_LIGHTING, false);
        wo->mesh->setID(ID_IsNotPickable);
        wo->mesh->setName(wo->name.c_str());

        return 0;
    }

    int woAddCubeMesh(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        if (wo->mesh != nullptr) wo->mesh->drop();

        wo->mesh = s_sMgr->addCubeSceneNode();
        wo->mesh->setID(ID_IsNotPickable);
        wo->mesh->setMaterialFlag(video::EMF_LIGHTING, false);
        wo->mesh->setMaterialTexture(0, s_driver->getTexture("resources/textures/moderntile.jpg"));
        wo->mesh->setPosition(vector3df(10.5f, 0.f, 10.5f));      // Default cubes are 10 big
        wo->mesh->setName(wo->name.c_str());

        return 0;
    }

    int woAddTriSelector(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        scene::ITriangleSelector* selector = 0;
        selector = s_sMgr->createTriangleSelectorFromBoundingBox(wo->mesh);
        wo->mesh->setTriangleSelector(selector);
        selector->drop();

        return 0;
    }

    int woSetPosition(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

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
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        float x = lua_tonumber(L, -3);
        float y = lua_tonumber(L, -2);
        float z = lua_tonumber(L, -1);

        wo->mesh->setScale(vector3df(x, y, z));

        return 0;
    }

    int woSetTexture(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        io::path fpath = lua_tostring(L, -1);
        wo->mesh->setMaterialTexture(0, s_driver->getTexture(fpath));

        return 0;
    }

    int woSetTransparent(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        wo->mesh->setMaterialType(EMT_TRANSPARENT_ADD_COLOR);
        return 0;
    }

    int woGetPosition(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        lua_pushnumber(L, wo->pos.X);
        lua_pushnumber(L, wo->pos.Y);
        lua_pushnumber(L, wo->pos.Z);

        return 3;
    }

    int woToggleBB(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

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
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        wo->mesh->setID(IDFlag_IsPickable);
        return 0;
    }

    int woCollides(lua_State* L)
    {
        WorldObject* wo1 = checkObject<WorldObject>(L, 2, "mt_WorldObject");
        WorldObject* wo2 = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        bool intersects = wo1->mesh->getTransformedBoundingBox().intersectsWithBox(wo2->mesh->getTransformedBoundingBox());
        lua_pushboolean(L, intersects);
        return 1;
    }

    int woDrawLine(lua_State* L)
    {
        WorldObject* wo1 = checkObject<WorldObject>(L, 2, "mt_WorldObject");
        WorldObject* wo2 = checkObject<WorldObject>(L, 1, "mt_WorldObject");

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

    int isRMBPressed(lua_State* L)
    {
        bool rmbPressed = s_evRec->isRMBPressed();

        lua_pushboolean(L, rmbPressed);
        return 1;
    }

    int isKeyDown(lua_State* L)
    {
        std::string key = lua_tostring(L, -1);
        bool keyDown = s_evRec->isKeyDown(key);
        lua_pushboolean(L, keyDown);
        return 1;
    }

    // Utility (Non Lua Func)
    ISceneNode* irrlichtCastRay(const vector3df& start, vector3df dir)
    {
        core::line3d<f32> ray;
        ray.start = start;
        ray.end = ray.start + dir.normalize() * 1000.0f;

        core::vector3df intersection;
        core::triangle3df hitTriangle;

        ISceneNode* ret = s_collMan->getSceneNodeAndCollisionPointFromRay(
            ray,
            intersection,
            hitTriangle,
            IDFlag_IsPickable,
            0);

        return ret;
    }

    // Camera
    int createCamera(lua_State* L)
    {
        Camera** cam = reinterpret_cast<Camera**>(lua_newuserdata(L, sizeof(Camera*)));
        *cam = new Camera;

        luaL_getmetatable(L, "mt_Camera");
        lua_setmetatable(L, -2);

        //std::cout << "Camera allocated!\n";

        return 1;
    }

    int deallocateCamera(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
            delete cam;
        //std::cout << "[C++]: Camera deallocated!\n";

        return 0;
    }

    int camCreateFPS(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            cam->sceneCam = s_sMgr->addCameraSceneNodeFPS();
            cam->sceneCam->setPosition({ 20, 5, -5 });
            cam->sceneCam->setID(ID_IsNotPickable);
        }

        return 0;
    }

    int camSetPosition(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        float x = lua_tonumber(L, -3);
        float y = lua_tonumber(L, -2);
        float z = lua_tonumber(L, -1);
        cam->sceneCam->setPosition(vector3df(x, y, z));

        return 0;
    }

    int camGetPosition(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            lua_pushnumber(L, cam->sceneCam->getAbsolutePosition().X);
            lua_pushnumber(L, cam->sceneCam->getAbsolutePosition().Y);
            lua_pushnumber(L, cam->sceneCam->getAbsolutePosition().Z);
        }

        return 3;
    }

    int camGetRightVec(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            // the world dirs are in COLUMNS (remember transpose of WM)
            const matrix4& mat = cam->sceneCam->getViewMatrix();

            // normalize incase its not orthonormal (it should be :))
            vector3df rightVec = vector3df(mat[0], mat[4], mat[8]).normalize();

            lua_pushnumber(L, rightVec.X);
            lua_pushnumber(L, rightVec.Y);
            lua_pushnumber(L, rightVec.Z);
        }
        return 3;
    }

    int camGetUpVec(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            vector3df upVec = cam->sceneCam->getUpVector();

            lua_pushnumber(L, upVec.X);
            lua_pushnumber(L, upVec.Y);
            lua_pushnumber(L, upVec.Z);
        }
        return 3;
    }

    int camGetForwardVec(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            const matrix4& mat = cam->sceneCam->getViewMatrix();
            vector3df forwardVec = vector3df(mat[2], mat[6], mat[10]).normalize();

            lua_pushnumber(L, forwardVec.X);
            lua_pushnumber(L, forwardVec.Y);
            lua_pushnumber(L, forwardVec.Z);

            /*
            --> in i lua 
            --> create vec
            --> return vec
            
            */
        }
        return 3;
    }

    int camCastRay(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            static ISceneNode* highlightedSceneNode = nullptr;

            if (highlightedSceneNode)
                highlightedSceneNode->setDebugDataVisible(0);   // reset debug bb


            // get fwd
            const matrix4& mat = cam->sceneCam->getViewMatrix();
            vector3df forwardVec = vector3df(mat[2], mat[6], mat[10]).normalize();

            std::string hitName = "";
            ISceneNode* selectedSceneNode = irrlichtCastRay(cam->sceneCam->getAbsolutePosition(), forwardVec);
            if (selectedSceneNode)
            {
                highlightedSceneNode = selectedSceneNode;
                hitName = highlightedSceneNode->getName();
                selectedSceneNode->setDebugDataVisible(irr::scene::EDS_BBOX);   // debug bb draw
            }

            lua_pushstring(L, hitName.c_str());
        }
        return 1;
       
    }
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

        // Setup statics for Lua usage
        luaF::s_sMgr = m_sMgr;
        luaF::s_evRec = &m_evRec;
        luaF::s_driver = m_driver;
        luaF::s_collMan = m_collMan;
    }
    
    // Init lua state
    L = luaL_newstate();
    luaL_openlibs(L);   // Open commonly used libs

    // Register World Object representation
    {
        luaL_newmetatable(L, "mt_WorldObject");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createWO },
        { "__gc", luaF::deallocateWO },
        { "removeNode", luaF::destroyWO },

        { "test", luaF::woTest },

        { "addSphereMesh", luaF::woAddSphereMesh },
        { "addCubeMesh", luaF::woAddCubeMesh },
        { "addCasting", luaF::woAddTriSelector },

        { "setPosition", luaF::woSetPosition },
        { "setScale", luaF::woSetScale }, 
        { "setTexture", luaF::woSetTexture },
        { "setPickable", luaF::woSetPickable },
        { "setTransparent", luaF::woSetTransparent  },

        { "getPosition", luaF::woGetPosition },

        { "toggleBB", luaF::woToggleBB  },
        { "collidesWith", luaF::woCollides  },
        { "drawLine", luaF::woDrawLine  },

        

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CWorldObject");    // set the configured metatable to "CWorldObject"
    }

    // Register Camera representation
    {
        luaL_newmetatable(L, "mt_Camera");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createCamera },
        { "__gc", luaF::deallocateCamera },

        { "setPosition", luaF::camSetPosition },
        { "createFPSCam", luaF::camCreateFPS },

        { "getRightVec", luaF::camGetRightVec },
        { "getForwardVec", luaF::camGetForwardVec },
        { "getUpVec", luaF::camGetUpVec },
        { "getPosition", luaF::camGetPosition },

        { "castRayForward", luaF::camCastRay },

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CCamera");
    }

    // Register input functions
    lua_register(L, "isLMBpressed", luaF::isLMBPressed);
    lua_register(L, "isRMBpressed", luaF::isRMBPressed);
    lua_register(L, "isKeyDown", luaF::isKeyDown);
   
    // Load scripts
    luaF::load_script(L, "main.lua");
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
        // Get delta time
        const u32 now = m_dev->getTimer()->getTime();
        const f32 dt = (f32)(now - then) / 1000.f;  // in sec
        then = now;

        m_driver->beginScene(true, true, SColor(255, 100, 101, 140));

		Update(dt);

        // Draw
        m_sMgr->drawAll();
        m_guiEnv->drawAll();
        m_driver->endScene();

        std::wstring title = std::wstring(L"Tower Defense. FPS: ") + std::to_wstring(1.0 / dt);
        m_dev->setWindowCaption(title.c_str());

	}
}

void Game::Init()
{
    // Init Lua
    lua_getglobal(L, "init");
    if (lua_isfunction(L, -1))
        luaF::pcall_p(L, 0, 0, 0);


    // Get time now
    then = m_dev->getTimer()->getTime();
}

void Game::Update(float dt)
{
    // Lua main update
    lua_getglobal(L, "update");
	if (lua_isfunction(L, -1)) 
    {
		lua_pushnumber(L, dt);
        luaF::pcall_p(L, 1, 0, 0);
	}
}