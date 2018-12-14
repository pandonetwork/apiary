import React from 'react'
import styled from 'styled-components'
import { Field, TextInput, Button } from '@aragon/ui'
import Aragon, { providers } from '@aragon/client'
import web3Utils from 'web3-utils'

const app = new Aragon(new providers.WindowMessage(window.parent))


class UpdateTapPanel extends React.Component {
  static defaultProps = {}

  state = { tap: 0 }

  handleSubmit = event => {
    event.preventDefault()
    app.updateTap(this.state.tap)
  }

  handleUpdate = event => {
    const tap = web3Utils.toWei(event.target.value, 'ether') / (24 * 3600)
    this.setState({ tap })
  }

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <Field label="New tap (ETH / day)">
          <TextInput.Number required wide step="any" onChange={this.handleUpdate}/>
        </Field>
        <ButtonWrapper>
          <Button mode="strong" type="submit" wide>Update tap</Button>
        </ButtonWrapper>
      </form>
    )
  }
}

const ButtonWrapper = styled.div`
  padding-top: 10px;
`
export default UpdateTapPanel
