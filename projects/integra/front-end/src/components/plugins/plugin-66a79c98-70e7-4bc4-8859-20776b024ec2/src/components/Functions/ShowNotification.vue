<template>
    <wwEditorInputRow
        label="Title"
        type="query"
        :model-value="notif_title"
        bindable
        required
        placeholder="Enter notification title"
        @update:modelValue="setTitle"
    />
    <wwEditorInputRow
        label="Body"
        type="query"
        :model-value="notif_body"
        bindable
        placeholder="Enter notification body"
        @update:modelValue="setBody"
    />
    <wwEditorInputRow
        label="Icon URL"
        type="query"
        :model-value="notif_icon"
        bindable
        placeholder="Enter icon URL"
        @update:modelValue="setIcon"
    />
    <wwEditorInputRow
        label="Image URL"
        type="query"
        :model-value="notif_image"
        bindable
        placeholder="Enter image URL"
        @update:modelValue="setImage"
    />
    <wwEditorInputRow
        label="Tag"
        type="query"
        :model-value="notif_tag"
        bindable
        placeholder="Enter notification tag"
        @update:modelValue="setTag"
    />
    <wwEditorInputRow
        label="Data (JSON format)"
        type="query"
        :model-value="notif_data"
        bindable
        placeholder="Enter notification data"
        @update:modelValue="setData"
    />
    <wwEditorInputRow
        label="Vibration Pattern (Array of numbers)"
        type="array"
        :model-value="notif_vibrate"
        bindable
        placeholder="Enter vibration pattern"
        @update:modelValue="setVibrate"
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
        notif_title() {
            return this.args.notif_title;
        },
        notif_body() {
            return this.args.notif_body;
        },
        notif_icon() {
            return this.args.notif_icon;
        },
        notif_image() {
            return this.args.notif_image;
        },
        notif_tag() {
            return this.args.notif_tag;
        },
        notif_data() {
            return this.args.notif_data;
        },
        notif_vibrate() {
            return this.args.notif_vibrate;
        },
    },
    methods: {
        setTitle(notif_title) {
            this.$emit('update:args', { ...this.args, notif_title });
        },
        setBody(notif_body) {
            this.$emit('update:args', { ...this.args, notif_body });
        },
        setIcon(notif_icon) {
            this.$emit('update:args', { ...this.args, notif_icon });
        },
        setImage(notif_image) {
            this.$emit('update:args', { ...this.args, notif_image });
        },
        setTag(notif_tag) {
            this.$emit('update:args', { ...this.args, notif_tag });
        },
        setData(notif_data) {
            this.$emit('update:args', { ...this.args, notif_data });
        },
        setVibrate(notif_vibrate) {
            this.$emit('update:args', { ...this.args, notif_vibrate });
        },
    },
};
</script>
