<template>
    <div class="ww-input-file" @click="openFileExplorer" :class="{ editing: isEditing }">
        <wwElement class="ww-input-file__button" v-bind="content.button" />
        <wwElement
            class="ww-input-file__text"
            v-bind="content.text"
            :ww-props="{ text: fileName || 'No file chosen' }"
        />
        <input
            ref="inputFile"
            :value="localValue"
            class="ww-input-file__input"
            type="file"
            :name="wwElementState.name"
            :required="content.required"
            :readonly="isReadonly"
            :multiple="content.multiple"
            :accept="accept"
            @input="handleManualInput($event)"
        />
    </div>
</template>

<script>
export default {
    props: {
        content: { type: Object, required: true },
        uid: { type: String, required: true },
        wwElementState: { type: Object, required: true },
    },
    emits: ['trigger-event', 'add-state', 'remove-state'],
    setup(props) {
        const { value: variableValue, setValue } = wwLib.wwVariable.useComponentVariable({
            uid: props.uid,
            name: 'value',
            defaultValue: null,
            componentType: 'element',
            type: 'file',
            readonly: true,
            resettable: true,
        });

        wwLib.wwVariable.useComponentVariable({
            uid: props.uid,
            name: 'progress',
            defaultValue: 0,
            componentType: 'element',
            type: 'number',
            readonly: true,
        });

        return { variableValue, setValue };
    },
    data() {
        return {
            localValue: null,
            fileName: null,
        };
    },
    computed: {
        isEditing() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        value() {
            return this.variableValue;
        },
        accept() {
            switch (this.content.accept) {
                case 'image':
                    return 'image/*';
                case 'video':
                    return 'video/*';
                case 'audio':
                    return 'audio/*';
                case 'pdf':
                    return '.pdf';
                case 'csv':
                    return '.csv';
                case 'excel':
                    return '.xls,.xlsb,.xlsm,.xlsx';
                case 'word':
                    return '.doc,.docm,.docx';
                case 'json':
                    return '.json';
                case 'custom':
                    return this.content.acceptCustom;
                case 'any':
                default:
                    return '';
            }
        },
        isReadonly() {
            return this.wwElementState.props.readonly === undefined
                ? this.content.readonly
                : this.wwElementState.props.readonly;
        },
    },
    watch: {
        variableValue(newValue) {
            if (newValue === null) {
                this.localValue = null;
                this.fileName = null;
            }
        },
        isReadonly: {
            immediate: true,
            handler(value) {
                if (value) {
                    this.$emit('add-state', 'readonly');
                } else {
                    this.$emit('remove-state', 'readonly');
                }
            },
        },
    },
    methods: {
        handleManualInput(event) {
            const value = event.target.value;
            if (value === this.localValue) return;
            const isMultiple = this.content.multiple;
            const files = this.$refs['inputFile'].files;
            if (!files || !files.length) return;
            this.localValue = value;
            this.fileName = files.length > 1 ? `${files.length} files` : files[0].name;
            this.setValue(isMultiple ? files : files[0]);
            this.$emit('trigger-event', {
                name: 'change',
                event: { domEvent: event, value: isMultiple ? files : files[0] },
            });
        },
        openFileExplorer() {
            if (this.isEditing || this.isReadonly) return;
            this.$refs['inputFile'].click();
        },
    },
};
</script>

<style lang="scss" scoped>
.ww-input-file {
    align-items: center;
    position: relative;

    &__input {
        position: absolute;
        opacity: 0;
        pointer-events: none !important;
    }
}
</style>
