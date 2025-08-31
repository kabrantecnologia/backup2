<template>
    <div class="ww-recaptcha">
        <div
            v-if="!isHidden"
            v-show="content.key"
            :id="`ww-recaptcha-${wwElementState.uid}`"
            :name="wwElementState.name"
            :data-send-response="content.sendResponse"
            data-callback="wwReCaptchaCallback"
            data-expired-callback="wwReCaptchaExpiredCallback"
        ></div>
    </div>
</template>

<script>
import { computed } from 'vue';

export default {
    props: {
        wwElementState: { type: Object, required: true },
        content: { type: Object, required: true },
        uid: { type: String, required: true },
    },
    emits: ['trigger-event'],
    setup(props) {
        const { value: variableValue, setValue } = wwLib.wwVariable.useComponentVariable({
            uid: props.uid,
            name: 'value',
            type: 'object',
            defaultValue: computed(() =>
                props.content.value === undefined ? { validate: false, code: null } : props.content.value
            ),
        });

        return { variableValue, setValue };
    },
    data() {
        return {
            isHidden: false,
        };
    },
    computed: {
        value() {
            return this.variableValue;
        },
    },
    mounted() {
        this.addScript();
    },
    created() {
        wwLib.getFrontWindow().wwReCaptchaCallback = this.callback;
        wwLib.getFrontWindow().wwReCaptchaExpiredCallback = this.expiredCallback;
    },
    methods: {
        addScript() {
            const functionName = `onRecaptchaLoad-${this.wwElementState.uid}`.replace(/-/g, '');
            wwLib.getFrontWindow()[functionName] = this.render;

            const scriptElement = wwLib.getFrontDocument().createElement('script');
            scriptElement.setAttribute(
                'src',
                `https://www.google.com/recaptcha/api.js?onload=${functionName}&render=explicit`
            );
            scriptElement.setAttribute('type', 'text/javascript');
            scriptElement.setAttribute('async', true);
            scriptElement.setAttribute('defer', true);
            wwLib.getFrontDocument().head.appendChild(scriptElement);
        },
        render() {
            wwLib.getFrontWindow().grecaptcha.render(`ww-recaptcha-${this.wwElementState.uid}`, {
                sitekey: this.content.key,
                theme: this.content.theme,
                size: this.content.size,
            });
        },
        callback(code) {
            const value = {
                validate: !!code,
                code: code || null,
            };
            this.setValue(value);
            this.$emit('trigger-event', { name: 'change', event: { value } });
        },
        expiredCallback() {
            this.callback(null);
        },
    },
};
</script>

<style lang="scss" scoped>
.ww-recaptcha {
}
</style>
