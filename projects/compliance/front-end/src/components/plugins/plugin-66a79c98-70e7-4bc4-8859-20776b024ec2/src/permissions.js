export const requestDeviceMotionPermission = async () => {
    try {
        if (typeof DeviceMotionEvent.requestPermission === 'function') {
            return await DeviceMotionEvent.requestPermission();
        }
    } catch (error) {
        throw new Error('Device motion permission request failed', error);
    }
};
