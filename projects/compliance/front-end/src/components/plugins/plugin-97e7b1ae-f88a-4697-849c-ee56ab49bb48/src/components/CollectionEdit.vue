<template>
    <div class="javascript-collection-edit">
        <wwEditorFormRow label="Javascript code">
            <wwEditorInputCode name="js-code" :model-value="content.js" @update:modelValue="setProp('js', $event)" />
        </wwEditorFormRow>
    </div>
</template>

<script>
export default {
    props: {
        config: { type: Object, required: true },
    },
    emits: ['update:config'],
    computed: {
        content() {
            return {
                js: 'return { test: "my code is always working" }',
                ...this.config,
            };
        },
    },
    mounted() {
        this.setProp('js', this.content.js);
    },
    methods: {
        setProp(key, value) {
            this.$emit('update:config', { ...this.content, [key]: value });
        },
    },
};
</script>

<style scoped lang="scss">
.javascript-collection-edit {
    display: flex;
    flex-direction: column;
}
</style>
