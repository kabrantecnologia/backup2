export default {
    editor: {
        label: {
            en: 'reCAPTCHA v2',
        },
        icon: 'finger-print',
    },
    triggerEvents: [{ name: 'change', label: { en: 'Change' }, event: { value: '' }, default: true }],
    properties: {
        theme: {
            label: {
                en: 'Theme',
                fr: 'Theme',
            },
            type: 'TextSelect',
            options: {
                options: [
                    {
                        value: 'light',
                        label: { en: 'Light' },
                    },
                    { value: 'dark', label: { en: 'Dark' } },
                ],
            },
            defaultValue: 'light',
        },
        size: {
            label: {
                en: 'Size',
                fr: 'Size',
            },
            type: 'TextSelect',
            options: {
                options: [
                    {
                        value: 'normal',
                        label: { en: 'Normal' },
                    },
                    { value: 'compact', label: { en: 'Compact' } },
                ],
            },
            defaultValue: 'normal',
        },
        key: {
            section: 'settings',
            label: {
                en: 'Site Key reCaptcha v2',
            },
            options: {
                placeholder: 'key',
            },
            type: 'Text',
            bindable: true,
            defaultValue: '',
        },
        sendResponse: {
            section: 'settings',
            label: {
                en: 'Send value at form submit',
            },
            type: 'OnOff',
            defaultValue: false,
        },
    },
};
