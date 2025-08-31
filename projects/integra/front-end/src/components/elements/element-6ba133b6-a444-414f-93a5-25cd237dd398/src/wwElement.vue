<template>
    <component
        :is="isEditing ? 'div' : 'label'"
        class="ww-webapp-checkbox"
        :style="cssVariables"
        :class="{ editing: isEditing }"
        :for="`${wwElementState.name}-${uniqueId}-${uid}`"
    >
        <input
            :id="`${wwElementState.name}-${uniqueId}-${uid}`"
            ref="checkboxInput"
            :checked="value"
            :value="value"
            type="checkbox"
            :name="`${wwElementState.name}-${uniqueId}-${uid}`"
            :class="content.checkbox && 'hidden'"
            :required="content.required"
            :disabled="isReadonly"
            v-bind="attributes"
            @input="handleManualInput($event)"
            @click.stop
        />
        <component
            :is="isEditing ? 'div' : 'label'"
            v-if="content.checkbox"
            :for="`${wwElementState.name}-${uniqueId}-${uid}`"
        >
            <wwElement v-bind="content.checkbox" :states="checkboxStates"></wwElement>
        </component>

        <component :is="isEditing ? 'div' : 'label'" :for="`${wwElementState.name}-${uniqueId}-${uid}`">
            <wwElement
                v-if="content.isEmbeddedContainer"
                class="embedded-container"
                v-bind="content.embeddedContainer"
            ></wwElement>
        </component>
    </component>
</template>

<script>
import { computed } from 'vue';

export default {
    props: {
        content: { type: Object, required: true },
        wwFrontState: { type: Object, required: true },
        wwElementState: { type: Object, required: true },
        uid: { type: String, required: true },
    },
    emits: ['update:content:effect', 'trigger-event', 'add-state', 'remove-state'],
    setup(props) {
        const { value: variableValue, setValue } = wwLib.wwVariable.useComponentVariable({
            uid: props.uid,
            name: 'value',
            type: 'boolean',
            defaultValue: computed(() => (props.content.value === undefined ? false : props.content.value)),
        });


        return {
            variableValue,
            setValue,
            uniqueId: wwLib.wwUtils.getUid(),

        };
    },
    computed: {
        value() {
            return !!this.variableValue;
        },
        isEditing() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        isSelected() {
            // eslint-disable-next-line no-unreachable
            return false;
        },
        cssVariables() {
            let flexDirection = 'row';
            if (this.content.containerPosition === 'left' || this.content.containerPosition === 'right') {
                if (this.content.containerPosition === 'left') flexDirection = 'row-reverse';
                else flexDirection = 'row';
            } else {
                if (this.content.containerPosition === 'top') flexDirection = 'column-reverse';
                else flexDirection = 'column';
            }

            return {
                '--container-direction': flexDirection,
            };
        },
        isReadonly() {
            return this.wwElementState.props.readonly === undefined
                ? this.content.readonly
                : this.wwElementState.props.readonly;
        },
        attributes() {
            return this.wwElementState.props.attributes;
        },
        checkboxStates() {
            const states = [];
            if (this.value && !this.isSelected) {
                states.push('checked');
            }
            if (this.isReadonly) {
                states.push('readonly');
            }
            return states;
        },
    },
    watch: {
        'content.value'(newValue) {
            newValue = !!newValue;
            if (newValue === this.value) return;
            this.setValue(newValue);
            this.$emit('trigger-event', { name: 'initValueChange', event: { value: newValue } });
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
            const value = !!event.target.checked;
            if (value === this.value) return;
            this.setValue(value);
            this.$emit('trigger-event', { name: 'change', event: { domEvent: event, value } });
        },
    },
};
</script>

<style lang="scss" scoped>
:root {
    --container-direction: row;
}
.ww-webapp-checkbox {
    flex-direction: var(--container-direction);
    align-items: center;
    position: relative;
    isolation: isolate;

    & .hidden {
        position: absolute;
        top: 0;
        left: 0;
        opacity: 0;
        pointer-events: none;
    }
}
</style>
