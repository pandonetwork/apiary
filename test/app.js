const Kit = artifacts.require('Kit')


contract('Kit', (accounts) => {
  it('it should deploy', async () => {
    const kit = await Kit.new('0x5f6f7e8cc7346a11ca2def8f827b7a0b612c56a1')

  })
  it('it should not revert on newInstance()', async () => {
    const receipt = await kit.newInstance()

  })
})
