#include "my_application.h"

int main(int argc, char** argv) {
  g_set_prgname("local_ecosystem");
  g_set_application_name("Local Ecosystem");
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
