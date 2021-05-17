#include "Game.h"

std::wstring s2ws(const std::string& s)
{
    int len;
    int stringlength = (int)s.length() + 1;

    len = MultiByteToWideChar(CP_ACP, 0, s.c_str(), stringlength, 0, 0);
    wchar_t* buf = new wchar_t[len];

    MultiByteToWideChar(CP_ACP, 0, s.c_str(), stringlength, buf, len);
    std::wstring r(buf);
    delete[] buf;
    return r;
}

namespace luaF
{
    static int s_GUI_idstart = 101;
    static IrrlichtDevice* s_dev = nullptr;
    static ISceneManager* s_sMgr = nullptr;
    static EventReceiver* s_evRec = nullptr;
    static IVideoDriver* s_driver = nullptr;
    static ISceneCollisionManager* s_collMan = nullptr;
    static IGUIEnvironment* s_guiEnv = nullptr;

    static lua_State* s_L = nullptr;
    // old
    /* WorldObject* checkWO(lua_State* L, int n)
     {
         void* ptr = luaL_testudata(L, n, "mt_WorldObject");
         WorldObject* wo = nullptr;
         if (ptr != nullptr)
             wo = *(WorldObject**)ptr;
         return wo;
     }*/


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


    int exitApp(lua_State* L)
    {
        s_dev->closeDevice();
        return 0;
    }


    // Check user data from stack
    template<typename T>
    T* checkObject(lua_State* L, int n, const std::string& metatable)
    {
        // A ptr is held in the Lua environment!
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
            // A ptr is held in the Lua environment.
            WorldObject** wo = reinterpret_cast<WorldObject**>(lua_newuserdata(L, sizeof(WorldObject*)));
            *wo = new WorldObject;
            (*wo)->name = name;

            luaL_getmetatable(L, "mt_WorldObject");
            lua_setmetatable(L, -2);    // pops table from stack and sets it as new metatb for the idx value! 
                                        // mt_WorldObject is at top and we set it on userdata below it

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
                wo->mesh->removeAll();
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
        //wo->mesh->setMaterialTexture(0, s_driver->getTexture("resources/textures/moderntile.jpg"));
        //wo->mesh->setPosition(vector3df(10.5f, 0.f, 10.5f));      // Default cubes are 10 big
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

    int woSetDynamic(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        wo->dynamic = true;
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

    int woToggleVisible(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        if (wo->meshVisible)
        {
            wo->mesh->setVisible(false);
            wo->meshVisible = false;
        }
        else
        {
            wo->mesh->setVisible(true);
            wo->meshVisible = true;
        }
        return 0;
    }

    int woSetMoveNextPoint(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");

        if (!(wo->dynamic))
            throw std::runtime_error("Object is not set to be dynamic!");
        
        vector3df start;
        start.X = lua_tonumber(L, -7);
        start.Y = lua_tonumber(L, -6);
        start.Z = lua_tonumber(L, -5);

        vector3df end;
        end.X = lua_tonumber(L, -4);
        end.Y = lua_tonumber(L, -3);
        end.Z = lua_tonumber(L, -2);

        float interpTime = lua_tonumber(L, -1);

        //std::cout << "Start: (" << start.X << ", " << start.Y << ", " << start.Z << ")\n";
        //std::cout << "End: (" << end.X << ", " << end.Y << ", " << end.Z << ")\n";
        //std::cout << "Interp time: " << interpTime << '\n';
        //std::cout << "Next move assigned to: " << wo->mesh->getName() << '\n';

        wo->mover.AssignNextMove(start, end, interpTime);
        // std::cout << "Assigned\n";
        return 0;
    }

    int woUpdate(lua_State* L)
    {
        WorldObject* wo = checkObject<WorldObject>(L, 1, "mt_WorldObject");
        float dt = lua_tonumber(L, -1);
            
        if (!(wo->mover.dead) && wo->dynamic)
        {
            wo->pos = wo->mover.Update(dt, wo->mesh->getName());
            wo->mesh->setPosition(wo->pos);
        }
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

    int isKeyPressed(lua_State* L)
    {
        std::string key = lua_tostring(L, -1);
        bool keyPressed = s_evRec->isKeyPressed(key);
        lua_pushboolean(L, keyPressed);
        return 1;
    }

    // Skybox
    int setSkyboxTextures(lua_State* L)
    {
        io::path topPath = lua_tostring(L, -6);
        io::path bottomPath = lua_tostring(L, -5);
        io::path leftPath = lua_tostring(L, -4);
        io::path rightPath = lua_tostring(L, -3);
        io::path frontPath = lua_tostring(L, -2);
        io::path backPath = lua_tostring(L, -1);

        std::cout << topPath.c_str() << '\n';

        auto top = s_driver->getTexture(topPath);
        auto bottom = s_driver->getTexture(bottomPath);
        auto left = s_driver->getTexture(leftPath);
        auto right = s_driver->getTexture(rightPath);
        auto front = s_driver->getTexture(frontPath);
        auto back = s_driver->getTexture(backPath);

        s_sMgr->addSkyBoxSceneNode(top, bottom, left, right, front, back);

        return 0;
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

        std::cout << "Hola!\n";

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

        float x = lua_tonumber(L, -3);
        float y = lua_tonumber(L, -2);
        float z = lua_tonumber(L, -1);


        if (cam != nullptr)
        {
            cam->sceneCam = s_sMgr->addCameraSceneNodeFPS();
            cam->sceneCam->setPosition({ x, y, z });
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

    static ISceneNode* s_highlightedSceneNode = nullptr;
    int camCastRay(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            if (s_highlightedSceneNode)
                s_highlightedSceneNode->setDebugDataVisible(0);   // reset debug bb

            // get fwd
            const matrix4& mat = cam->sceneCam->getViewMatrix();
            vector3df forwardVec = vector3df(mat[2], mat[6], mat[10]).normalize();

            std::string hitName = "";
            ISceneNode* selectedSceneNode = irrlichtCastRay(cam->sceneCam->getAbsolutePosition(), forwardVec);
            if (selectedSceneNode)
            {
                s_highlightedSceneNode = selectedSceneNode;
                hitName = s_highlightedSceneNode->getName();
                selectedSceneNode->setDebugDataVisible(irr::scene::EDS_BBOX);   // debug bb draw
            }
            else
            {
                s_highlightedSceneNode = nullptr;
            }
            

            lua_pushstring(L, hitName.c_str());
        }
        return 1;
       
    }

    int camToggleActive(lua_State* L)
    {
        Camera* cam = checkObject<Camera>(L, 1, "mt_Camera");

        if (cam != nullptr)
        {
            cam->active = !(cam->active);
            cam->sceneCam->setInputReceiverEnabled(cam->active);
        }
        return 1;
    }

    int drawLine(lua_State* L)
    {
        float startX = lua_tonumber(L, -6);
        float startY = lua_tonumber(L, -5);
        float startZ = lua_tonumber(L, -4);

        float endX = lua_tonumber(L, -3);
        float endY = lua_tonumber(L, -2);
        float endZ = lua_tonumber(L, -1);

        s_driver->setTransform(video::ETS_WORLD, core::IdentityMatrix);
        s_driver->draw3DLine(vector3df(startX, startY, startZ), vector3df(endX, endY, endZ), SColor(255, 255, 0, 255));

        return 0;
    }

    // GUI
    int clearGUI(lua_State* L)
    {
        s_guiEnv->clear();
        return 0;
    }

    int setGlobalGUIFont(lua_State* L)
    {
        std::string fontpath = lua_tostring(L, -1);
        IGUISkin* skin = s_guiEnv->getSkin();
        IGUIFont* font = s_guiEnv->getFont(s2ws(fontpath).c_str());
        if (font)
            skin->setFont(font);

        return 0;
    }
    
    // Text
    int createText(lua_State* L)
    {
        float topLeftX = lua_tonumber(L, -6);
        float topLeftY = lua_tonumber(L, -5);
        float pixWidth = lua_tonumber(L, -4);
        float pixHeight = lua_tonumber(L, -3);
        std::string initText = lua_tostring(L, -2);
        std::string fontpath = lua_tostring(L, -1);

        GUIStaticText** txt = reinterpret_cast<GUIStaticText**>(lua_newuserdata(L, sizeof(GUIStaticText*)));
        *txt = new GUIStaticText;
        
        (*txt)->ptr = s_guiEnv->addStaticText(s2ws(initText).c_str(), rect<s32>(
            topLeftX, topLeftY, topLeftX + pixWidth, topLeftY + pixHeight));

        IGUIFont* font = s_guiEnv->getFont(fontpath.c_str());
        (*txt)->ptr->setOverrideFont(font);

        luaL_getmetatable(L, "mt_GUIText");
        lua_setmetatable(L, -2);

        return 1;
    }

    int removeText(lua_State* L)
    {
        GUIStaticText* txt = checkObject<GUIStaticText>(L, 1, "mt_GUIText");

        if (txt != nullptr)
        {
            txt->ptr->setVisible(false);
            delete txt;     // let irrlicht take care of the underlying ptr (crash if we drop internal ptr here)
        }

        return 0;
    }

    int setText(lua_State* L)
    {
        std::string newText = lua_tostring(L, -1);

        GUIStaticText* text = checkObject<GUIStaticText>(L, 1, "mt_GUIText");

        text->ptr->setText(s2ws(newText).c_str());
        return 0;
    }

    int setTextBGColor(lua_State* L)
    {
        float r = lua_tonumber(L, -4);
        float g = lua_tonumber(L, -3);
        float b = lua_tonumber(L, -2);
        float a = lua_tonumber(L, -1);

        GUIStaticText* text = checkObject<GUIStaticText>(L, 1, "mt_GUIText");

        text->ptr->setBackgroundColor(SColor(a, r, g, b));
        return 0;
    }


    int setTextColor(lua_State* L)
    {
        float r = lua_tonumber(L, -4);
        float g = lua_tonumber(L, -3);
        float b = lua_tonumber(L, -2);
        float a = lua_tonumber(L, -1);

        GUIStaticText* text = checkObject<GUIStaticText>(L, 1, "mt_GUIText");

        text->ptr->setOverrideColor(SColor(a, r, g, b));
        return 0;
    }

    // Button
    int createButton(lua_State* L)
    {
        float topLeftX = lua_tonumber(L, -7);
        float topLeftY = lua_tonumber(L, -6);
        float pixWidth = lua_tonumber(L, -5);
        float pixHeight = lua_tonumber(L, -4);

        float internalID = lua_tonumber(L, -3);
        int irrID = s_GUI_idstart + internalID;

        std::string text = lua_tostring(L, -2);
        std::string fontpath = lua_tostring(L, -1);

        GUIButton** button = reinterpret_cast<GUIButton**>(lua_newuserdata(L, sizeof(GUIButton*)));
        *button = new GUIButton;

        (*button)->ptr = s_guiEnv->addButton(rect<s32>(topLeftX, topLeftY, topLeftX + pixWidth, topLeftY + pixHeight), 
            0, irrID, s2ws(text).c_str());

        IGUIFont* font = s_guiEnv->getFont(fontpath.c_str());
        (*button)->ptr->setOverrideFont(font);

        luaL_getmetatable(L, "mt_GUIButton");
        lua_setmetatable(L, -2);

        return 1;
    }

    int removeButton(lua_State* L)
    {
        GUIButton* button = checkObject<GUIButton>(L, 1, "mt_GUIButton");

        if (button != nullptr)
        {
            button->ptr->setVisible(false);
            delete button;     // let irrlicht take care of the underlying ptr (crash if we drop internal ptr here)
        }

        return 0;
    }

    int openFileDialog(lua_State* L)
    {
        float internalID = lua_tonumber(L, -1);
        int irrID = s_GUI_idstart + internalID;

        s_guiEnv->addFileOpenDialog(L"Please choose a file!", true, 0, irrID, true);
        return 0;
    }

    // Scrollbar
    int createScrollbar(lua_State* L)
    {
        float topLeftX = lua_tonumber(L, -7);
        float topLeftY = lua_tonumber(L, -6);
        float pixWidth = lua_tonumber(L, -5);
        float pixHeight = lua_tonumber(L, -4);

        float min = lua_tonumber(L, -3);
        float max = lua_tonumber(L, -2);

        float internalID = lua_tonumber(L, -1);
        int irrID = s_GUI_idstart + internalID;


        GUIScrollbar** sb = reinterpret_cast<GUIScrollbar**>(lua_newuserdata(L, sizeof(GUIScrollbar*)));
        *sb = new GUIScrollbar;

        (*sb)->ptr = s_guiEnv->addScrollBar(true,
            rect<s32>(topLeftX, topLeftY, topLeftX + pixWidth, topLeftY + pixHeight), 0, irrID);

        (*sb)->ptr->setPos(min);
        (*sb)->ptr->setMin(min);
        (*sb)->ptr->setMax(max);

        luaL_getmetatable(L, "mt_GUIScrollbar");
        lua_setmetatable(L, -2);


        return 1;
    }

    int removeScrollbar(lua_State* L)
    {
        GUIScrollbar* sb = checkObject<GUIScrollbar>(L, 1, "mt_GUIScrollbar");

        if (sb != nullptr)
        {
            sb->ptr->setVisible(false);
            delete sb;     // let irrlicht take care of the underlying ptr (crash if we drop internal ptr here)
        }

        return 0;
    }

    // Listbox
    int createListbox(lua_State* L)
    {
        float topLeftX = lua_tonumber(L, -5);
        float topLeftY = lua_tonumber(L, -4);
        float pixWidth = lua_tonumber(L, -3);
        float pixHeight = lua_tonumber(L, -2);

        float internalID = lua_tonumber(L, -1);
        int irrID = s_GUI_idstart + internalID;

        GUIListbox** lb = reinterpret_cast<GUIListbox**>(lua_newuserdata(L, sizeof(GUIListbox*)));
        *lb = new GUIListbox;

        (*lb)->ptr = s_guiEnv->addListBox(rect<s32>(topLeftX, topLeftY, topLeftX + pixWidth, topLeftY + pixHeight), 0, irrID, true);

        luaL_getmetatable(L, "mt_GUIListbox");
        lua_setmetatable(L, -2);

        return 1;
    }

    int removeListbox(lua_State* L)
    {
        GUIListbox* lb = checkObject<GUIListbox>(L, 1, "mt_GUIListbox");

        if (lb != nullptr)
        {
            lb->ptr->setVisible(false);
            delete lb;     // let irrlicht take care of the underlying ptr (crash if we drop internal ptr here)
        }

        return 0;
    }

    int addToListbox(lua_State* L)
    {
        std::string text = lua_tostring(L, -1);

        GUIListbox* lb = checkObject<GUIListbox>(L, 1, "mt_GUIListbox");

        lb->ptr->addItem(s2ws(text).c_str());

        return 0;
    }

    int resetListboxContent(lua_State* L)
    {
        GUIListbox* lb = checkObject<GUIListbox>(L, 1, "mt_GUIListbox");
        lb->ptr->clear();

        return 0;
    }


    int createEditbox(lua_State* L)  
    {
        float topLeftX = lua_tonumber(L, -4);
        float topLeftY = lua_tonumber(L, -3);
        float pixWidth = lua_tonumber(L, -2);
        float pixHeight = lua_tonumber(L, -1);

        GUIEditbox** eb = reinterpret_cast<GUIEditbox**>(lua_newuserdata(L, sizeof(GUIEditbox*)));
        *eb = new GUIEditbox;

        (*eb)->ptr = s_guiEnv->addEditBox(L"",
            rect<s32>(topLeftX, topLeftY, topLeftX + pixWidth, topLeftY + pixHeight)
        );

        luaL_getmetatable(L, "mt_GUIEditbox");
        lua_setmetatable(L, -2);

        return 1;
    }

    int removeEditbox(lua_State* L)
    {
        GUIEditbox* eb = checkObject<GUIEditbox>(L, 1, "mt_GUIEditbox");

        if (eb != nullptr)
        {
            eb->ptr->setVisible(false);
            delete eb;     // let irrlicht take care of the underlying ptr (crash if we drop internal ptr here)
        }

        return 0;
    }


    int getTextEditbox(lua_State* L)
    {
        GUIListbox* lb = checkObject<GUIListbox>(L, 1, "mt_GUIEditbox");
        std::wstring txt = lb->ptr->getText();

        std::string ret = std::string(txt.begin(), txt.end());
        
        lua_pushstring(L, ret.c_str());

        return 1;
    }

    int setTextEditbox(lua_State* L)
    {
        GUIListbox* lb = checkObject<GUIListbox>(L, 1, "mt_GUIEditbox");
        std::string txt = lua_tostring(L, -1);

        lb->ptr->setText(s2ws(txt).c_str());

        return 0;
    }

}

vector3df LinInterpMover::Update(float dt, const std::string& id)
{
    currTime += dt;

    vector3df newPos;

    // StartPos is starting point and (endPos - startPos) is the direction of movement where the rate of change of the 
    // magnitude is linearly proportional to (currTime/maxTime)
    if (currTime >= maxTime)
    {
        newPos = endPos;
        done = true;

        currTime = 0.0;

        // Return to Lua to ask for next move
        lua_getglobal(luaF::s_L, "getNextWaypoint");
        if (lua_isfunction(luaF::s_L, -1))
        {
            lua_pushstring(luaF::s_L, id.c_str());
            luaF::pcall_p(luaF::s_L, 1, 1, 0);

            bool succeeded = lua_toboolean(luaF::s_L, -1);
            
            // If coroutine died, don't update movement anymore
            if (!succeeded)
            {
                currTime = 0.f;
                maxTime = -1.f;
                dead = true;
            }
        }
    }
    else if (!done)
    {
        // Normal interp
        newPos = startPos + (endPos - startPos) * (currTime / maxTime);
    }
    else if (done)
    {
        // Set at end
        newPos = endPos;
    }


    return newPos;
}

void LinInterpMover::AssignNextMove(const vector3df& start, const vector3df& end, float time)
{
    // Double-check move is indeed done before new interp assignment
    if (done)
    {
        startPos = start;
        endPos = end;
        maxTime = time;
        done = false;
    }
}

bool EventReceiver::OnEvent(const SEvent& event)
{
    if (event.EventType == irr::EET_KEY_INPUT_EVENT)
    {
        // held down
        m_keyIsDown[event.KeyInput.Key] = event.KeyInput.PressedDown;

        //// pressed and released
        //if (event.KeyInput.PressedDown == false)
        //{
        //    m_keyWasPressed[event.KeyInput.Key] = true;
        //}

        // check first "down" (a.k.a pressed)
        if (m_not_held)
        {
            m_not_held = false;
            // transition from false to true
            if (m_keyWasPressed[event.KeyInput.Key] == false)
            {
                m_keyWasPressed[event.KeyInput.Key] = true;
            }
        }

        // allow above check again only if has been released
        if (event.KeyInput.PressedDown == false)
        {
            m_not_held = true;
            m_keyWasPressed[event.KeyInput.Key] = false;    // if released, we make sure to turn it off
        }
    }

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

    if (event.EventType == irr::EET_GUI_EVENT)
    {
        s32 id = event.GUIEvent.Caller->getID();
        int internalID = id - luaF::s_GUI_idstart;
        s32 pos = 0;

        switch (event.GUIEvent.EventType)
        {
        case EGET_SCROLL_BAR_CHANGED:
            pos = ((IGUIScrollBar*)event.GUIEvent.Caller)->getPos();

            // call lua with ID and new scrollbar value

            lua_getglobal(luaF::s_L, "scrollbarEvent");
            if (lua_isfunction(luaF::s_L, -1))
            {
                lua_pushnumber(luaF::s_L, internalID);
                lua_pushnumber(luaF::s_L, pos);
                luaF::pcall_p(luaF::s_L, 2, 0, 0);
            }
            break;

        case EGET_BUTTON_CLICKED:
            //// call lua with ID
            //std::cout << id << " Button clicked!\n";

            lua_getglobal(luaF::s_L, "buttonClickEvent");
            if (lua_isfunction(luaF::s_L, -1))
            {
                lua_pushnumber(luaF::s_L, internalID);
                luaF::pcall_p(luaF::s_L, 1, 0, 0);
            }

            break;

        case EGET_FILE_SELECTED:

            IGUIFileOpenDialog* fileDialog = (IGUIFileOpenDialog*)event.GUIEvent.Caller;

            lua_getglobal(luaF::s_L, "fileSelected");
            if (lua_isfunction(luaF::s_L, -1))
            {
                std::wstring wstr(fileDialog->getFileName());
                std::string str(wstr.begin(), wstr.end());

                std::cout << "Path: " << str << '\n';
                lua_pushstring(luaF::s_L, str.c_str());
                luaF::pcall_p(luaF::s_L, 1, 0, 0);
            }
            break;
        }


    }

    return false;
}


Game::Game() : then(0)
{
    // Init Irrlicht
    {
        m_dev = createDevice(
            video::EDT_OPENGL,
            dimension2d<u32>(1600, 900),
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
        luaF::s_dev = m_dev;
        luaF::s_sMgr = m_sMgr;
        luaF::s_evRec = &m_evRec;
        luaF::s_driver = m_driver;
        luaF::s_collMan = m_collMan;
        luaF::s_guiEnv = m_guiEnv;
    }

    // Init Lua
    ResetLuaState();
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
        if (m_dev->run())
        {
            m_sMgr->drawAll();
            m_guiEnv->drawAll();
            m_driver->endScene();

            std::wstring title = std::wstring(L"Tower Defense. FPS: ") + std::to_wstring(1.0 / dt);
            m_dev->setWindowCaption(title.c_str());
        }
	}
}

void Game::Init()
{
    // Get time now
    then = m_dev->getTimer()->getTime();
}

void Game::Update(float dt)
{
    // Lua main update
    if (L != nullptr && luaF::s_L != nullptr)
    {
        lua_getglobal(L, "update");
        if (lua_isfunction(L, -1))
        {
            lua_pushnumber(L, dt);
            luaF::pcall_p(L, 1, 0, 0);
        }
    }

    if (m_luaShouldReset)
    {
        ResetLuaState();
        m_luaShouldReset = false;
    }

    /*
    * 1) --> when quitting --> set flag (to reset lua state)
    * 2) --> after update loop ends
    * 3) --> actually handle replacement
    * 
    
    */
}

void Game::ResetLuaState()
{
    if (L != nullptr && luaF::s_L != nullptr)
    {
        lua_close(L);
        L = nullptr;
        luaF::s_L = nullptr;
        m_sMgr->clear();
        m_guiEnv->clear();
    }

    // Init lua state
    L = luaL_newstate();
    luaF::s_L = L;
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
        { "setDynamic", luaF::woSetDynamic  },
        { "setMoveNextPoint", luaF::woSetMoveNextPoint  },

        { "getPosition", luaF::woGetPosition },

        { "toggleBB", luaF::woToggleBB  },
        { "toggleVisible", luaF::woToggleVisible  },
        { "collidesWith", luaF::woCollides  },
        { "drawLine", luaF::woDrawLine  },

        { "update", luaF::woUpdate  },




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
        { "toggleActive", luaF::camToggleActive },

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CCamera");
    }

    // Register Button representation
    {
        luaL_newmetatable(L, "mt_GUIButton");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createButton },
        { "__gc", luaF::removeButton },


        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CButton");
    }

    // Register Static Text representation
    {
        luaL_newmetatable(L, "mt_GUIText");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createText },
        { "__gc", luaF::removeText },
        { "setText", luaF::setText },
        { "setBGColor", luaF::setTextBGColor },
        { "setColor", luaF::setTextColor },


        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CText");
    }

    // Register Scrollbar representation
    {
        luaL_newmetatable(L, "mt_GUIScrollbar");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createScrollbar },
        { "__gc", luaF::removeScrollbar },

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CScrollbar");
    }

    // Register Listbox representation
    {
        luaL_newmetatable(L, "mt_GUIListbox");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createListbox },
        { "__gc", luaF::removeListbox },
        { "addToList", luaF::addToListbox },
        { "reset", luaF::resetListboxContent },

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CListbox");
    }

    // Register Editbox representation
    {
        luaL_newmetatable(L, "mt_GUIEditbox");

        luaL_Reg funcRegs[] =
        {
        { "new", luaF::createEditbox },
        { "__gc", luaF::removeEditbox },
        { "getText", luaF::getTextEditbox },
        { "setText", luaF::setTextEditbox },

        { NULL, NULL }
        };

        luaL_setfuncs(L, funcRegs, 0);
        lua_pushvalue(L, -1);

        lua_setfield(L, -1, "__index");
        lua_setglobal(L, "CEditbox");
    }

    // Register misc global functions
    lua_register(L, "isLMBpressed", luaF::isLMBPressed);
    lua_register(L, "isRMBpressed", luaF::isRMBPressed);
    lua_register(L, "isKeyDown", luaF::isKeyDown);
    lua_register(L, "isKeyPressed", luaF::isKeyPressed);
    lua_register(L, "setSkyboxTextures", luaF::setSkyboxTextures);
    lua_register(L, "posDrawLine", luaF::drawLine);
    lua_register(L, "clearGUI", luaF::clearGUI);
    lua_register(L, "openFileDialog", luaF::openFileDialog);
    lua_register(L, "setGlobalGUIFont", luaF::setGlobalGUIFont);
    lua_register(L, "exitApp", luaF::exitApp);

    // Use Closure to access internal Game state through global lua func
    lua_pushlightuserdata(L, this);
    lua_pushcclosure(L, &Game::ResetLuaStateWrapper, 1);
    lua_setglobal(L, "resetLuaState");

    // Load scripts
    luaF::load_script(L, "main.lua");

    // Init Lua
    lua_getglobal(L, "init");
    if (lua_isfunction(L, -1))
        luaF::pcall_p(L, 0, 0, 0);
}

int Game::ResetLuaStateWrapper(lua_State* L)
{
    Game* gm = static_cast<Game*>(lua_touserdata(L, lua_upvalueindex(1)));

    //gm->ResetLuaState();
    gm->m_luaShouldReset = true;
    luaF::s_highlightedSceneNode = nullptr;

    return 0;
}
