/* SPDX-License-Identifier: Apache-2.0 */
/* Created & Support: chkd13303@gmail.com */
/* Donate: https://buymeacoffee.com/bbktto */

#include <stdio.h>
#include <sys/prctl.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#define print(...) \
        if(nprint >= 1) \
                fprintf(stderr,__VA_ARGS__);

void __attribute__((constructor)) load ()
{
  char fname[256] = { 0 };
  const char shells[][5] = { "ash", "zsh", "fish" };
  int nprint = 0;

  if (getenv ("KSM_SHOW_DEBUG"))
	nprint = 1;

  if (readlink ("/proc/self/exe", fname, sizeof (fname) - 1) != -1)
	{
	  for (int v = 0; v <= sizeof (shells) / sizeof (shells[0]) - 1; v++)
		{
		  char *ext = fname + (strlen (fname) - strlen (shells[v]));
		  if (strcmp (ext, shells[v]) == 0)
			{
			  if (getenv ("KSM_FORCE_SHELL"))
				{
				  print
					("KSM active on Shell force enabled by environment !\n");
				  break;
				}
			  print ("Found Shell, ignoring !\n");
			  return;
			}
		}
	}

  if (getenv ("KSM_UNSET_PRELOAD") && getenv ("LD_PRELOAD"))
	{
	  unsetenv ("LD_PRELOAD");
	  print ("remove LD_PRELOAD !\n");
	}

  int ret = -255;
  ret = prctl (67, 1, 0, 0, 0);
  if (ret >= 0)
	{
	  print ("KSM ON !\n");
	}
  else
	{
	  print ("KSM error %d\n", ret);
	}
  errno = 0;
}
