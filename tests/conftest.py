import pytest


@pytest.fixture
def sudo(accounts):
    return accounts[-1]


@pytest.fixture
def token(sudo, project):
    return sudo.deploy(project.Token)


@pytest.fixture
def vault(sudo, token, project):
    return sudo.deploy(project.VyperVault, token)
