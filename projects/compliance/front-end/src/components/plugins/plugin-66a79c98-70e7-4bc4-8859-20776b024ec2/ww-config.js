export default {
    editor: {
        designSystemId: '"2158285b-a489-44b6-be61-5cab2bec46fb"',
    },
    variables: [
        { name: 'network', value: 'network', type: 'object', defaultValue: null },
        { name: 'battery', value: 'battery', type: 'object', defaultValue: null },
        { name: 'pageVisibility', value: 'pageVisibility', type: 'boolean', defaultValue: false },
        {
            name: 'deviceMotion',
            value: 'deviceMotion',
            type: 'object',
            defaultValue: {
                acceleration: { x: -1, y: -1, z: -1 },
                accelerationIncludingGravity: { x: -1, y: -1, z: -1 },
                rotationRate: { alpha: -1, beta: -1, gamma: -1 },
                interval: -1,
                supported: false,
            },
        },
        { name: 'deviceInfo', value: 'deviceInfo', type: 'object', defaultValue: null },
        // { name: 'isPwaInstalled', value: 'isPwaInstalled', type: 'object', defaultValue: null },
    ],
    actions: [
        {
            name: 'Add To Home Screen',
            code: 'installPwa',
            isAsync: true,
        },
        {
            name: 'Geolocate',
            code: 'geolocation',
            isAsync: true,
            keywords: ['Android', 'iOS'],
        },
        {
            name: 'Share',
            code: 'share',
            isAsync: true,
        },
        {
            name: 'Vibrate',
            code: 'vibrate',
            isAsync: false,
        },
        {
            name: 'Show Notification',
            code: 'showNotification',
            isAsync: true,
        },
        {
            name: 'Request Motion Permission',
            code: 'requestDeviceMotionPermission',
            isAsync: true,
        },
        {
            name: 'Listen Device Motion',
            code: 'listenDeviceMotion',
            isAsync: true,
        },
    ],
};
