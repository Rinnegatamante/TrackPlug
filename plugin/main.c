#include <vitasdk.h>
#include <taihen.h>
#include <kuio.h>
#include <libk/string.h>
#include <libk/stdio.h>

static SceUID hook;
static tai_hook_ref_t ref;
static char titleid[16];
static char fname[256];
static uint64_t playtime = 0;
static uint64_t tick = 0;

int sceDisplaySetFrameBuf_patched(const SceDisplayFrameBuf *pParam, int sync) {
	
	uint64_t t_tick = sceKernelGetProcessTimeWide();
	
	// Saving playtime every 10 seconds
	if ((t_tick - tick) > 10000000){
		tick = t_tick;
		playtime += 10;
		SceUID fd;
		kuIoOpen(fname, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, &fd);
		kuIoWrite(fd, &playtime, sizeof(uint64_t));
		kuIoClose(fd);
	}
	
	return TAI_CONTINUE(int, ref, pParam, sync);
} 

void _start() __attribute__ ((weak, alias ("module_start")));
int module_start(SceSize argc, const void *args) {
	
	// Getting game Title ID
	sceAppMgrAppParamGetString(0, 12, titleid , 256);
	
	// Getting current playtime
	SceUID fd;
	sprintf(fname, "ux0:/data/TrackPlug/%s.bin", titleid);
	kuIoOpen(fname, SCE_O_RDONLY, &fd);
	if (fd >= 0){
		kuIoRead(fd, &playtime, sizeof(uint64_t));
		kuIoClose(fd);
	}
	
	// Getting starting tick
	tick = sceKernelGetProcessTimeWide();
	
	hook = taiHookFunctionImport(&ref,
						TAI_MAIN_MODULE,
						TAI_ANY_LIBRARY,
						0x7A410B64,
						sceDisplaySetFrameBuf_patched);
	
	return SCE_KERNEL_START_SUCCESS;
}

int module_stop(SceSize argc, const void *args) {

	return SCE_KERNEL_STOP_SUCCESS;
	
}