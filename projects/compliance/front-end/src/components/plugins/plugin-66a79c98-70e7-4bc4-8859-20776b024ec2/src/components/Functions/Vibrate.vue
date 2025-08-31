<template>
    <div>
        <wwEditorInputRow
            label="Vibration Pattern"
            type="array"
            :model-value="vibrate_pattern"
            bindable
            required
            placeholder="Enter vibration pattern"
            @update:modelValue="setPattern"
        />
    </div>
</template>

<script>
export default {
    props: {
        plugin: { type: Object, required: true },
        args: { type: Object, required: true },
    },
    emits: ['update:args'],
    computed: {
        vibrate_pattern() {
            return this.args.vibrate_pattern;
        },
    },
    methods: {
        setPattern(vibrate_pattern) {
            this.$emit('update:args', { ...this.args, vibrate_pattern });
        },
    },
};
</script>
