<template>
    <wwEditorInputRow
        label="Title"
        type="query"
        :model-value="share_title"
        bindable
        required
        placeholder="Enter the title"
        @update:modelValue="setTitle"
    />
    <wwEditorInputRow
        label="Text"
        type="query"
        :model-value="share_text"
        bindable
        placeholder="Enter the text"
        @update:modelValue="setText"
    />
    <wwEditorInputRow
        label="Url"
        type="query"
        :model-value="share_url"
        bindable
        required
        placeholder="Enter the url"
        @update:modelValue="setUrl"
    />
</template>

<script>
export default {
    props: {
        plugin: { type: Object, required: true },
        args: { type: Object, required: true },
    },
    emits: ['update:args'],
    computed: {
        share_title() {
            return this.args.share_title;
        },
        share_text() {
            return this.args.share_text;
        },
        share_url() {
            return this.args.share_url;
        },
        share_files() {
            return this.args.share_files;
        },
    },
    methods: {
        setTitle(share_title) {
            this.$emit('update:args', { ...this.args, share_title });
        },
        setText(share_text) {
            this.$emit('update:args', { ...this.args, share_text });
        },
        setUrl(share_url) {
            this.$emit('update:args', { ...this.args, share_url });
        },
    },
};
</script>
