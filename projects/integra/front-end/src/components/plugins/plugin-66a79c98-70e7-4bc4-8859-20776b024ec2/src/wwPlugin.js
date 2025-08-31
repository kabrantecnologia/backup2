// import { getMimeType, convertURLToFile } from './utils';
import { geolocation } from './services/geolocation';
import { share } from './services/share';
import { vibrate } from './services/vibrate';
import { showNotification } from './services/notification';
import { requestDeviceMotionPermission } from './permissions';

import { listenNetwork, listenBattery, listenPageVisibility, listenDeviceMotion, getDeviceInfo } from './variables';

export default {
    networkState: null,
    batteryState: null,
    pageVisibilityState: null,
    deviceMotionState: null,
    deviceInfoState: null,

    async onLoad(settings) {
        this.networkState = listenNetwork(this.id);
        this.batteryState = listenBattery(this.id);
        this.pageVisibilityState = listenPageVisibility(this.id);
        this.deviceMotionState = listenDeviceMotion(this.id);
        this.deviceInfoState = getDeviceInfo(this.id);
    },
    async geolocation() {
        return geolocation();
    },
    async share(shareOptions) {
        return share(shareOptions);
    },
    async vibrate(vibrateOptions) {
        return vibrate(vibrateOptions);
    },
    async showNotification(notificationOptions) {
        return showNotification(notificationOptions);
    },
    async requestDeviceMotionPermission() {
        return requestDeviceMotionPermission();
    },
    async listenDeviceMotion() {
        return await listenDeviceMotion(this.id);
    },
    async installPwa() {
        if (wwLib.installPwaPrompt) {
            try {
                await wwLib.installPwaPrompt.prompt();
            } catch (error) {
                throw new Error('PWA installation failed');
            }
        } else {
            throw new Error('Install prompt not available');
        }
    },
};
