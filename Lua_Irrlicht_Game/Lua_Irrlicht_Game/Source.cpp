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