#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <psp2/io/dirent.h>
#include <psp2/io/fcntl.h>
#include <psp2/io/stat.h>
#include <psp2/appmgr.h>
#include <psp2/kernel/processmgr.h>

int main_thread(SceSize args, void *argp) {
	
	// Creating required folders for TrackPlug if they don't exist
	sceIoMkdir("ux0:/data/TrackPlug", 0777);
	
	// Getting game Title ID
	char titleid[16], filename[256];
	sceAppMgrAppParamGetString(0, 12, titleid , 256);
	
	// Recovering current playtime
	sprintf(filename, "ux0:/data/TrackPlug/%s.bin", titleid);
	uint64_t playtime = 0;
	int fd = sceIoOpen(filename, SCE_O_RDONLY, 0777);
	if (fd >= 0){
		sceIoRead(fd, &playtime, sizeof(uint64_t));
		sceIoClose(fd);
	}
	
	for (;;){
	
		// We update the tracking plugin every 10 secs
		sceKernelDelayThread(10 * 1000 * 1000);
		playtime+=10;
		
		// Updating the tracking file
		int fd = sceIoOpen(filename, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
		sceIoWrite(fd, &playtime, sizeof(uint64_t));
		sceIoClose(fd);
	
	}

	return 0;
}

int _start(SceSize args, void *argp) {
	SceUID thid = sceKernelCreateThread("TrackPlug", main_thread, 0x40, 0x100000, 0, 0, NULL);
	if (thid >= 0)
		sceKernelStartThread(thid, 0, NULL);

	return 0;
}